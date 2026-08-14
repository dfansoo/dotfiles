# ~/.zshrc

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

alias ls='eza --icons'
alias ll='eza -la --icons'
alias cat='bat'
alias vim='nvim'

eval "$(fnm env --use-on-cd)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

eval "$(starship init zsh)"
