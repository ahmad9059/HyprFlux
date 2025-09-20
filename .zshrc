# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="refined"

plugins=( 
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-vi-mode
)



source $ZSH/oh-my-zsh.sh

# Enable Vim Mode
bindkey -v

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux


# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos



### From this line is for pywal-colors
# Import colorscheme from 'wal' asynchronously
# &   # Run the process in the background.
# ( ) # Hide shell job control messages.
# Not supported in the "fish" shell.
#(cat ~/.cache/wal/sequences &)

# Alternative (blocks terminal for 0-3ms)
#cat ~/.cache/wal/sequences

# To add support for TTYs this line can be optionally added.
#source ~/.cache/wal/colors-tty.sh

# My alias 

alias cty='tty-clock -S -c -C 6 -t -n -D'
alias fucking='sudo'
alias n='nvim'
alias t='tmux'
alias ta='tmux attach'
alias tl='tmux ls'
alias cd..='cd ..'
alias gc='git clone '
alias ga='git add .'
alias gcm='git commit -m '
alias gp='git push -u orign main'
alias gs='git status'
alias ll='ls -Alh'
alias ls='lsd --group-dirs first'
alias cat='bat'
alias gc='g++ -o o'
alias py='python3'
alias py='python3'
alias c='sudo rsync -avhW --no-compress --progress '
alias code='code --ozone-platform=x11'
alias kiro='kiro --ozone-platform=x11'
alias y='yazi'
alias md1='sudo mount /dev/sda5 /mnt/vmachines'
alias md2='sudo mount /dev/sda4 /mnt/windows-drive'
alias web='tmuxifier load-session web-dev'
alias lg='lazygit'
alias nivm='nvim'
alias pdf='firefox'
alias cd='z'
alias s='yay -Ss '
alias i='yay -S '
alias u='yay -Syu '
alias tk='tmux kill-server'
alias ntest='bash /home/ahmad/.config/hypr/UserScripts/networkTest.sh'
alias server2='ssh -i ~/.ssh/ssh-key-2025-09-06.key ubuntu@140.245.24.242'
alias server='ssh -i ~/.ssh/myVM.pem ubuntu@15.206.122.181'

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory


# exports
export LC_TIME=ur_PK.UTF-8
export PATH="$HOME/.tmuxifier/bin:$PATH"
export LIBVIRT_DEFAULT_URI='qemu:///system'
eval "$(zoxide init zsh)"
eval "$(tmuxifier init -)"
export PATH=$PATH:/home/ahmad/.spicetify
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"


# # >>> conda initialize >>>
# # !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/ahmad/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/ahmad/anaconda3/etc/profile.d/conda.sh" ]; then
#         . "/home/ahmad/anaconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/ahmad/anaconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# # <<< conda initialize <<<
#
