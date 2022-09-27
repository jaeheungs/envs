# Use antigen
source $HOME/.antigen.zsh

# Set locale
export LANG=en_US.UTF-8

# Use Oh-My-Zsh
antigen use oh-my-zsh

# Set theme
antigen theme sunrise

# Set plugins
antigen bundle git
antigen bundle pip
antigen bundle npm
antigen bundle python
antigen bundle docker
antigen bundle docker-compose
antigen bundle chrissicool/zsh-256color
antigen bundle esc/conda-zsh-completion
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting

# Set autosuggest settings
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"
ZSH_AUTOSUGGEST_USE_ASYNC="true"

# Set binding for delete word
bindkey -M main -M emacs '^H' backward-kill-word
bindkey -M main -M emacs '^[[3;5~' kill-word

# Apply changes
antigen apply

alias rez="source ~/.zshrc"
