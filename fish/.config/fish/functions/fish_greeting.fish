function fish_greeting --description "One-line greeting themed from the hypr-shell colors"
    set -l up (uptime -p | string replace -r '^up ' '' \
        | string replace -ra ' days?' 'd' \
        | string replace -ra ' hours?' 'h' \
        | string replace -ra ' minutes?' 'm' \
        | string replace -a ', ' ' ')

    # Mini terminal in the panel: a tiny palette-colored line.
    if set -q HS_MINITERM
        set -l dim (set_color $fish_color_comment)
        echo (set_color $fish_color_command)\uf303" "\
            (set_color --bold $fish_color_command)"hi, $USER"(set_color normal)$dim' · '(set_color $fish_color_end)(date +%H:%M)$dim' · '(set_color $fish_color_escape)"up $up"(set_color normal)
        return
    end

    set -l host $hostname
    set -l pretty (grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2- | tr -d '"')
    set -l os (string replace ' Linux' '' -- (string replace -r ' \(.*\)' '' $pretty))
    set -l sep (set_color $fish_color_comment)' · '(set_color $fish_color_normal)
    echo (set_color --bold $fish_color_command)$USER@$host(set_color normal)$sep$os$sep'fish '$version$sep'up '$up(set_color normal)
end
