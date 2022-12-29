########################
# Environment variables 
########################

# https://help.ubuntu.com/community/EnvironmentVariables#List_of_common_environment_variables

export TERM="xterm-256color"
export COLORTERM="truecolor"
export PAPERSIZE="a4"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# locales
export LANG="de_DE.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"

# prompt of less command
export LESS="-c -M -S -i -f -R"

# remove duplicate entries from $PATH
# zsh uses $path array along with $PATH 
typeset -U PATH path

# set PATH so it includes user's private bin if it exists
[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"
[ -d "$HOME/bin/scripts" ] && export PATH="$HOME/bin/scripts:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"