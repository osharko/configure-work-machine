# ─── ~/.config/fish/config.fish — gestito da chezmoi ─────────────────────
# Eredita config CachyOS (abbreviations base, fastfetch greeting) e aggiunge il mio.

if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# Path
fish_add_path -p $HOME/.local/bin

# ─── Tooling ────────────────────────────────────────────────────────────────
type -q mise; and mise activate fish | source
type -q zoxide; and zoxide init fish | source
type -q direnv; and direnv hook fish | source

# starship sostituisce Pure (vendor_conf.d/_pure_init.fish): basta caricarlo dopo
type -q starship; and starship init fish | source

# fzf shell integration
test -f /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish; and fzf_key_bindings 2>/dev/null
test -f /usr/share/fzf/key-bindings.fish; and source /usr/share/fzf/key-bindings.fish

# Brew (se installato manualmente)
test -f /home/linuxbrew/.linuxbrew/bin/brew; and /home/linuxbrew/.linuxbrew/bin/brew shellenv | source

# ─── Modern CLI replacements ────────────────────────────────────────────────
if type -q eza
    alias ls 'eza -lh --group-directories-first --icons=auto'
    alias lsa 'ls -a'
    alias lt 'eza --tree --level=2 --long --icons --git'
    alias lta 'lt -a'
end
type -q bat; and alias cat 'bat --paging=never'
type -q dust; and alias du 'dust'
type -q duf; and alias df 'duf'
type -q procs; and alias ps 'procs'
type -q btop; and alias top 'btop'; and alias htop 'btop'
# rg/fd hanno sintassi diversa da grep/find → no alias che oscuri i comandi standard
# (usali direttamente: rg <pattern> / fd <pattern>)

# ─── Aliases / abbreviations ────────────────────────────────────────────────
alias ff "fzf --preview 'bat --style=numbers --color=always {}'"
function eff
    set f (ff)
    test -n "$f"; and $EDITOR $f
end

alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'

abbr -a g git
abbr -a gcm 'git commit -m'
abbr -a gcam 'git commit -a -m'
abbr -a d docker
abbr -a t 'tmux attach; or tmux new -s Work'

function n
    if test (count $argv) -eq 0
        nvim .
    else
        nvim $argv
    end
end

# chezmoi: wrapper shell-agnostic in ~/.local/bin/chezmoi (precede /usr/bin/
# via fish_add_path). Aggiunge --force a `apply` per skip prompt
# all-overwrite/diff/skip/quit. Vedi dot_local/bin/executable_chezmoi.
# (Niente fish function: non funzionerebbe da bash/zsh quando lanci script.)

# vim → nvim (alias + abbreviation)
abbr -a vim 'nvim'
abbr -a vi  'nvim'

# Distrobox: dx <name> per entrare in qualunque container
abbr -a dx     'distrobox enter'
abbr -a dxl    'distrobox list'

# SSH machines (host alias da ~/.ssh/config)
abbr -a minis 'ssh minis'
abbr -a nas 'ssh nas'
abbr -a dell 'ssh dell'
abbr -a gpu-pc 'ssh gpu-pc'

# Claude
abbr -a cx 'printf "\033[2J\033[3J\033[H" && claude --permission-mode bypassPermissions'

# ─── Workspace shortcuts ────────────────────────────────────────────────────
# Workspace-specific env (gitignored): copia ~/.config/configure-work-machine/workspaces.fish
# da ~/.config/configure-work-machine/workspaces.fish.example e popola con le tue var.
test -f ~/.config/configure-work-machine/workspaces.fish; and source ~/.config/configure-work-machine/workspaces.fish
