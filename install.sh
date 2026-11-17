#!/usr/bin/env bash
# hypr-shell installer for Arch Linux and Fedora (one repo, one script).
#
#   ./install.sh                full install: packages, dotfiles, templates, system tweaks
#   ./install.sh --dry-run      print what would happen, change nothing
#   ./install.sh --check        only report missing programs, fonts and icons
#   --no-packages               skip the package manager step
#   --no-optional               skip packages/<distro>-optional.txt
#   --no-system                 skip /etc and system services (the steps that need root besides packages)
#   --autostart                 start Hyprland (uwsm) on the first console after login, for setups without a display manager
#   --no-personal              skip the personal package (zh-notes tools, sing-box VPN scripts and units)
#   --yes                       do not ask the package manager for confirmation
#
# Safe to run again: dotfiles are re-stowed, existing files are never overwritten.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_PACKAGES=(apps bin fish hypr pipewire quickshell theme)

DRY=0 CHECK=0 PACKAGES=1 OPTIONAL=1 SYSTEM=1 PERSONAL=1 YES=0 AUTOSTART=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        --check) CHECK=1 ;;
        --no-packages) PACKAGES=0 ;;
        --no-optional) OPTIONAL=0 ;;
        --no-system) SYSTEM=0 ;;
        --no-personal) PERSONAL=0 ;;
        --yes) YES=1 ;;
        --autostart) AUTOSTART=1 ;;
        -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done
# The public checkout has no personal package.
[[ -d "$REPO/personal" ]] || PERSONAL=0

say() { printf '\n==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
run() { if (( DRY )); then printf '  [dry-run] %s\n' "$*"; else "$@"; fi; }
list() { grep -vE '^[[:space:]]*(#|$)' "$REPO/packages/$1"; }

distro() {
    local ids
    ids="$( . /etc/os-release; echo " ${ID:-} ${ID_LIKE:-} " )"
    case "$ids" in
        *" arch "*) echo arch ;;
        *" fedora "*) echo fedora ;;
        *) return 1 ;;
    esac
}
DISTRO="$(distro)" || die "only Arch and Fedora are supported (see /etc/os-release)"
(( EUID != 0 )) || die "run as your normal user, sudo is used where needed"

check() {
    local missing=0 c
    say "Checking required programs ($DISTRO)"
    for c in qs Hyprland hyprlock hypridle hyprpicker uwsm awww awww-daemon matugen grim wl-copy wl-paste cliphist \
             brightnessctl playerctl wpctl pactl powerprofilesctl notify-send gio gsettings kitty kitten fish stow \
             jq curl python3 nmcli bluetoothctl udisksctl nautilus qalc fcitx5 xdg-open; do
        command -v "$c" >/dev/null 2>&1 || { echo "  missing: $c"; missing=1; }
    done
    python3 -c 'import PIL' 2>/dev/null || { echo "  missing: python Pillow"; missing=1; }
    [[ -d /usr/share/icons/Papirus-Dark ]] || { echo "  missing: Papirus-Dark icons (Veil builds on them)"; missing=1; }
    [[ -e "$HOME/.local/share/icons/Veil/index.theme" ]] || { echo "  missing: Veil icon theme (run the dotfiles step)"; missing=1; }
    command -v rsvg-convert >/dev/null 2>&1 || command -v resvg >/dev/null 2>&1 \
        || { echo "  missing: rsvg-convert (librsvg), the accent cursor is built with it"; missing=1; }
    local fonts; fonts="$(fc-list 2>/dev/null || true)"
    grep -qi 'rubik' <<<"$fonts" || { echo "  missing: Rubik font (run the dotfiles step, then fc-cache)"; missing=1; }
    grep -qi 'JetBrains' <<<"$fonts" || { echo "  missing: JetBrains Mono font"; missing=1; }
    [[ -L "$HOME/.config/hypr/hyprland.lua" ]] || { echo "  missing: ~/.config/hypr/hyprland.lua link (run the dotfiles step)"; missing=1; }
    (( missing )) || echo "  all required parts are in place"
    say "Optional"
    for c in wtype tesseract magick ffmpeg spicetify cava; do
        command -v "$c" >/dev/null 2>&1 && echo "  found:   $c" || echo "  absent:  $c"
    done
    command -v qs >/dev/null && echo "  quickshell: $(qs --version 2>&1 | head -1)"
    command -v Hyprland >/dev/null && echo "  hyprland:   $(Hyprland --version 2>&1 | head -1)"
    return $missing
}

if (( CHECK )); then check; exit $?; fi

install_packages() {
    local req opt=()
    mapfile -t req < <(list "$DISTRO.txt")
    (( OPTIONAL )) && mapfile -t opt < <(list "$DISTRO-optional.txt")
    say "Packages ($DISTRO): ${#req[@]} required, ${#opt[@]} optional"
    case "$DISTRO" in
        arch)
            local flag=(--needed); (( YES )) && flag+=(--noconfirm)
            run sudo pacman -Syu "${flag[@]}" "${req[@]}"
            (( ${#opt[@]} )) && run sudo pacman -S "${flag[@]}" "${opt[@]}" || true ;;
        fedora)
            local flag=(); (( YES )) && flag+=(-y)
            run sudo dnf copr enable "${flag[@]}" lionheartp/Hyprland
            run sudo dnf install "${flag[@]}" "${req[@]}"
            (( ${#opt[@]} )) && { run sudo dnf install "${flag[@]}" --skip-unavailable "${opt[@]}" || warn "some optional packages were not installed"; } ;;
    esac
}

# Machines set up by hand have absolute links into this repo or plain copies of its files; stow refuses to touch
# them. Both are replaced here, but only when they are provably the same thing (link into this repo, or a copy
# with identical content), so no work is lost.
clear_stale_copies() {
    local pkg="$1" src rel target dir pass
    local -a doomed=()
    while IFS= read -r -d '' src; do
        rel="${src#"$REPO/$pkg/"}"
        target="$HOME/$rel"; dir="$(dirname "$target")"
        [[ -e "$target" || -L "$target" ]] || continue
        # a parent directory that is itself a link into the repo means the file is already in place
        [[ "$(realpath -m "$dir")" == "$REPO"/* ]] && continue
        if [[ -L "$target" ]]; then
            [[ "$(readlink "$target")" == "$REPO"/* ]] && doomed+=("$target")
        elif cmp -s "$src" "$target"; then
            doomed+=("$target")
        else
            # a file with different content: stow will report it, so nothing in this package is touched
            echo "  keeping $target (differs from the repo copy)"
            return 0
        fi
    done < <(find "$REPO/$pkg" \( -type f -o -type l \) -not -path '*/__pycache__/*' -not -name '.stow-local-ignore' -print0)
    for target in "${doomed[@]}"; do echo "  replacing $target"; run rm -f "$target"; done
}

install_dotfiles() {
    say "Dotfiles (stow into $HOME)"
    # Directories shared with other software must exist first, otherwise stow replaces them with one big link
    # and everything else written there (your own scripts, fish functions) would land inside this repo.
    run mkdir -p "$HOME/.config/hypr" "$HOME/.config/quickshell" "$HOME/.config/fish/conf.d" "$HOME/.config/fish/functions" \
        "$HOME/.local/bin" "$HOME/.local/lib" "$HOME/.local/share/zh-notes" "$HOME/.config/systemd/user" "$HOME/.local/share/fonts" "$HOME/.local/share/icons" "$HOME/.local/share/applications" \
        "$HOME/.local/state/hypr-shell" "$HOME/.config/pipewire/filter-chain.conf.d" "$HOME/.config/mpv"
    local p stow_args=(-R -d "$REPO" -t "$HOME") failed=()
    (( PERSONAL )) && STOW_PACKAGES+=(personal)
    (( DRY )) && stow_args=(-n -v "${stow_args[@]}")
    for p in "${STOW_PACKAGES[@]}"; do
        clear_stale_copies "$p"
        stow "${stow_args[@]}" "$p" || failed+=("$p")
    done
    if (( ${#failed[@]} )); then
        warn "stow found conflicts in: ${failed[*]}"
        warn "move the files it names out of the way (nothing was overwritten) and run the script again"
        return 1
    fi
    run fc-cache -f "$HOME/.local/share/fonts"
}

install_templates() {
    local dir; dir="$(xdg-user-dir TEMPLATES 2>/dev/null || true)"
    # xdg-user-dir answers with $HOME when no templates folder is configured
    [[ -n "$dir" && "$dir" != "$HOME" ]] || dir="$HOME/Templates"
    say "Nautilus templates -> $dir"
    run mkdir -p "$dir"
    local f dest
    for f in "$REPO"/files/Templates/*; do
        dest="$dir/$(basename "$f")"
        [[ -e "$dest" ]] && continue
        # a hard link keeps edits in sync with the repo; fall back to a copy across filesystems
        if (( DRY )); then echo "  [dry-run] link $dest"; else ln "$f" "$dest" 2>/dev/null || cp "$f" "$dest"; fi
    done
}

# Stock Bibata cursors: the fallback when the accent cursor (hs-cursor, built from the Bibata SVGs in the repo) cannot
# be built, and the theme for cursor.style "bibata" (white Ice on dark, black Classic on light). Not in the repo
# (27 MB each) and not in the Arch or Fedora repos: fetched from the GitHub release, pinned and checksummed.
BIBATA_VERSION="v2.0.7"
BIBATA_SUMS=(
    "Bibata-Modern-Ice a68cae60c4dc706350e194ebc91c5fe48bc7bc9d59e119555834a2a7ee5078ef"
    "Bibata-Modern-Classic 7d3495864e5bbef02f5e77de760b2905903b63c71495a78ef6306d19a3b556d8"
)
install_cursors() {
    say "Cursor theme (Bibata $BIBATA_VERSION)"
    local dir="$HOME/.local/share/icons" entry name sum tmp
    for entry in "${BIBATA_SUMS[@]}"; do
        read -r name sum <<<"$entry"
        if [[ -d "$dir/$name/cursors" || -d "/usr/share/icons/$name/cursors" ]]; then echo "  $name: present"; continue; fi
        if (( DRY )); then echo "  [dry-run] fetch $name"; continue; fi
        tmp="$(mktemp -d)"
        if curl -fsSL --max-time 300 -o "$tmp/$name.tar.xz" \
                "https://github.com/ful1e5/Bibata_Cursor/releases/download/$BIBATA_VERSION/$name.tar.xz" \
           && echo "$sum  $tmp/$name.tar.xz" | sha256sum -c --status; then
            mkdir -p "$dir" && tar -xf "$tmp/$name.tar.xz" -C "$dir" "$name" && echo "  $name: installed"
        else
            warn "could not fetch $name (no network or checksum mismatch); the cursor stays the system default"
        fi
        rm -rf "$tmp"
    done
}

# Default apps for media: mpv for video and audio, Loupe for pictures. Only types with no default yet are set,
# so a choice made in another app or by hand stays.
MEDIA_VIDEO="video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg video/ogg video/x-flv video/3gpp"
MEDIA_AUDIO="audio/mpeg audio/flac audio/x-flac audio/ogg audio/opus audio/x-wav audio/wav audio/aac audio/mp4 audio/x-m4a audio/webm"
MEDIA_IMAGE="image/jpeg image/png image/webp image/gif image/avif image/heif image/heic image/jxl image/bmp image/tiff image/svg+xml image/x-portable-pixmap"
install_defaults() {
    say "Default apps for media"
    command -v xdg-mime >/dev/null || { warn "xdg-mime missing, default apps not set"; return; }
    local app type set=0
    for type in $MEDIA_VIDEO $MEDIA_AUDIO $MEDIA_IMAGE; do
        case "$type" in image/*) app=org.gnome.Loupe.desktop ;; *) app=mpv.desktop ;; esac
        [[ -n "$(xdg-mime query default "$type" 2>/dev/null)" ]] && continue
        run xdg-mime default "$app" "$type"
        set=$((set + 1))
    done
    echo "  $set types set (the rest already had a default)"
}

install_personal() {
    say "Personal tools (zh-notes, sing-box VPN)"
    local zh="$HOME/.local/share/zh-notes"
    if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        echo "  no user session here: enabling the units is skipped (run the script again after logging in)"
        return 0
    fi
    run systemctl --user daemon-reload

    # Python environment for the zh command; the dictionaries and the database are data, not in the repo.
    if [[ ! -x "$zh/venv/bin/python" ]]; then
        run python3 -m venv "$zh/venv" && run "$zh/venv/bin/pip" install -q -r "$zh/requirements.txt" \
            || warn "could not build the zh-notes environment"
    fi
    [[ -s "$zh/cedict.db" ]] || echo "  zh-notes data is missing: copy ~/.local/share/zh-notes/{cedict.db,dicts,state.json} from the old machine"

    local blob="$REPO/secrets/sing-box.tar.age"
    if [[ ! -f "$HOME/.config/sing-box/config.json" && -f "$blob" ]]; then
        if (( DRY )); then echo "  [dry-run] hs-secrets unpack"
        elif [[ -t 0 ]] && command -v age >/dev/null; then
            echo "  sing-box configs are in the repo, encrypted: enter the passphrase"
            "$HOME/.local/bin/hs-secrets" unpack || warn "could not decrypt the sing-box configs"
        else
            echo "  sing-box configs are in the repo, encrypted: install age and run: hs-secrets unpack"
        fi
    fi
    if [[ -f "$HOME/.config/sing-box/config.json" ]]; then
        command -v sing-box >/dev/null 2>&1 || warn "sing-box is not installed (Arch: sudo pacman -S sing-box; Fedora: install the binary to /usr/local/bin)"
        run systemctl --user enable --now sing-box.service vpn-dns-pin.timer vpn-watchdog.timer
    else
        echo "  VPN is not enabled: ~/.config/sing-box/config.json is missing (it holds server keys);"
        echo "  run: hs-secrets unpack (needs age), then this script again"
    fi
    if [[ -d "$HOME/notes/chinese/.git" ]]; then
        run systemctl --user enable --now zh-git.timer
    else
        echo "  zh-git.timer is not enabled: ~/notes/chinese is not a git checkout (git clone git@github.com:anaidyss/chinese-notes.git ~/notes/chinese)"
    fi
}

install_system() {
    say "System settings (root needed)"
    run sudo install -Dm644 "$REPO/system/logind-hypr-shell.conf" /etc/systemd/logind.conf.d/50-hypr-shell.conf
    run sudo install -Dm644 "$REPO/system/70-hypr-shell-touchpad-edge.rules" /etc/udev/rules.d/70-hypr-shell-touchpad-edge.rules
    run sudo udevadm control --reload
    run sudo udevadm trigger --subsystem-match=hidraw
    echo "  lid switch is ignored from the next boot on"
    run sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service upower.service
    if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
        run systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service \
            || warn "could not enable the audio services for this user (they start on login on most setups)"
        # The Media tab equalizer (pipewire/.config/pipewire/filter-chain.conf.d/hs-eq.conf)
        run systemctl --user enable --now filter-chain.service || warn "could not start the equalizer (filter-chain.service)"
    fi
}

# Without a display manager the session has to be started by hand. This makes fish do it at the login on the first console.
install_autostart() {
    say "Hyprland autostart on the first console"
    local f="$HOME/.config/fish/conf.d/autostart-hyprland.fish"
    if [[ -e "$f" ]]; then echo "  already there: $f"; return 0; fi
    if (( DRY )); then echo "  [dry-run] write $f"; return 0; fi
    mkdir -p "$(dirname "$f")"
    cat > "$f" <<'EOS'
# Written by hypr-shell install.sh --autostart: log in on tty1 and Hyprland starts through uwsm.
if status is-login; and test -z "$WAYLAND_DISPLAY"; and test "$XDG_VTNR" = 1
    if uwsm check may-start
        exec uwsm start hyprland.desktop
    end
end
EOS
    echo "  wrote $f (needs fish as the login shell)"
}

(( PACKAGES )) && install_packages
install_dotfiles
install_templates
install_cursors
install_defaults
(( PERSONAL )) && install_personal
(( SYSTEM )) && install_system
(( AUTOSTART )) && install_autostart

say "Done"
cat <<EOF
Next:
  * Log in to Hyprland. Arch ships the session entry "Hyprland (uwsm-managed)", on Fedora use uwsm too;
    pick a display manager yourself, none is installed here, or run ./install.sh --autostart to start it from the first console.
  * The first login picks a wallpaper and paints the system from it (hs-wallpaper restore runs on start).
  * Check the result any time with: ./install.sh --check
EOF
if (( PERSONAL )); then cat <<EOF
  * The personal package (zh-notes tools, sing-box VPN scripts and units) is installed too, but needs data
    that is not in the repo: ~/.config/sing-box/config.json (server keys) and ~/.local/share/zh-notes/{cedict.db,dicts}.
EOF
fi
