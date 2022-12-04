alias zshconfig="code --new-window \
  ~/.zshrc \
  ~/.zlogout \
  ~/.oh-my-zsh/custom/aliases.zsh \
  ~/.oh-my-zsh/custom/functions.zsh \
  ~/.zshenv
"
alias sshconfig="code --new-window ~/.ssh/config"
alias hostconfig="code --new-window ~/etc/hosts"

alias grep="grep --color=auto"

## always ask with -i flag before you delete or move
# alias -g rmdir="rm -r -i"
# alias -g rm="rm -i"
# alias -g mv="mv -i"
## Safely trash files
[ ! -z $(command -v "trash") ] && alias rm=trash
alias python=python3
[ ! -z $(command -v "bat") ] && alias cat=bat

#search history
alias hist='history | grep'
# Get week number
alias week='date +%V'
# copy git branch name to clipboard (git plugin required)
alias gbc="current_branch | clipcopy"

# URL-encode URL strings (https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/functions.zsh#L130)
alias urlformencode='omz_urlencode'
[ -x $(command -v "omz_urlencode") ] && alias urlencode="omz_urldecode -P" || alias urlencode="python -c \"import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]));\""
# URL-decode URL strings (https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/functions.zsh#L211)
[ -x $(command -v "omz_urldecode") ] && alias urldecode="omz_urldecode" || alias urldecode="python -c \"import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]));\""

if [ -x "$(command -v exa)" ]; then

    # --git not available on ubuntu 22.04
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
      DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    else
      DISTRO=$(. /etc/os-release; echo "$NAME")
    fi
    [ ${DISTRO} != "Ubuntu" ] && git="--git"

    ## ls
    alias ls='exa --group-directories-first'
    alias lS='exa -1'
    ## list, size, type, git
    alias ll='exa -labFh --group-directories-first ${git}'
    ## long list                                 
    alias l='exa -labGF --group-directories-first ${git}'
    ## long list, modified date sort
    alias llm='exa -lbGd --sort modified ${git}'
    ## all list
    alias la='exa -lbhHigUmuSa --time-style=long-iso --group-directories-first --color-scale ${git}'
    ## all + extended list
    alias lx='exa -lbhHigUmuSa@ --time-style=long-iso --group-directories-first --color-scale ${git}'

    ## trees
    alias lt='exa -T --level=2 --group-directories-first'
    alias lT='exa -T --level=4 --group-directories-first'
    alias lt='exa -lT --level=2 --group-directories-first'
else
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
  alias lt='tree -aC -I ".git|node_modules|bower_components" -L 2 --dirsfirst'
fi
