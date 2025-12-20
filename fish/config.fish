function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    if not set -q SSH_AUTH_SOCK
        set -Ux SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
    end
end

if status is-interactive # Commands to run in interactive sessions can go here
    fastfetch

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'
    alias search "yay -Ss"
    alias install "yay -S --noconfirm"
    alias update "yay -Syu --noconfirm"
    alias remove "yay -Rns --noconfirm"
    alias n nvim
    alias cd z
    alias z zed
    alias h helix
    alias qs quickshell
    alias lg lazygit

end
zoxide init fish | source
