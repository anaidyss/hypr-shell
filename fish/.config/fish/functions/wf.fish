function wf --description 'Wi-Fi from the terminal: wf (menu), wf ls, wf <ssid>, wf off, wf eap <ssid>'
    switch "$argv[1]"
        case ''
            # Full-screen picker: arrows, Enter, asks for the password (or login) itself.
            nmtui connect
        case ls list
            nmcli -f IN-USE,SSID,SECURITY,SIGNAL,BARS device wifi list --rescan yes
        case off down
            set -l dev (nmcli -t -f DEVICE,TYPE device | string match -r '^[^:]+(?=:wifi$)')
            nmcli device disconnect $dev[1]
        case eap
            # 802.1X (campus) network: login and password, both asked interactively.
            set -q argv[2]; or begin; echo 'usage: wf eap <ssid>'; return 2; end
            read -P 'Login: ' -l user; or return 1
            read -s -P 'Password: ' -l pass; or return 1
            echo "Connecting to $argv[2]…"
            printf '%s\n%s\n%s\n' $argv[2] $user $pass | hs-wifi-eap
            switch $status
                case 0
                    echo "Connected to $argv[2]"
                case 4
                    echo "Login rejected or network out of reach (journalctl -u NetworkManager -n 40)" >&2
                    return 1
                case '*'
                    echo "Could not save the profile for $argv[2]" >&2
                    return 1
            end
        case -h --help help
            echo 'wf            pick a network (nmtui)'
            echo 'wf ls         list networks'
            echo 'wf <ssid>     connect, asks for the password if needed'
            echo 'wf eap <ssid> connect to an 802.1X network with login and password'
            echo 'wf off        disconnect Wi-Fi'
        case '*'
            # Saved networks come up without a question; new ones ask for the key.
            nmcli connection up id "$argv" 2>/dev/null
            or nmcli --ask device wifi connect "$argv"
    end
end
