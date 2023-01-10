#!/bin/bash

# call functions from terminal: 
# bash -c ". ~/.dotfiles/scripts/bash/user.sh && user_of_id 1000"

# checks if current or a given user is in group
# usage: if ingroup $1; then echo 'yes'; else echo 'no'; fi
function ingroup(){ [[ " `id -Gn ${2-}` " == *" $1 "* ]]; }

# returns the user of a provided UID
function user_of_id(){ awk -v val=${1:-1000} -F ":" '$3==val{print $1}' /etc/passwd; }

# returns the group of a provided GID
function group_of_id(){ awk -v val=${1:-1000} -F ":" '$3==val{print $1}' /etc/group; }


