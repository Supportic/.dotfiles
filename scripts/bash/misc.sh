#!/bin/bash

# call functions from terminal: 
# bash -c ". ~/.dotfiles/scripts/bash/misc.sh && sudoIf ls"

# check if a binary is installed
# usage: if command_exists "..."; then; fi
function command_exists() {
  # [ type $1 > /dev/null 2>&1 ]
  [ ! -z "$(command -v $1)" ]
}

# use sudo if current user is not root
# usage: sudoIf groupadd ...
function sudoIf() { if [ "$(id -u)" -ne 0 ]; then sudo "$@"; else "$@"; fi }

# regardless of capitalisation
# $ limits to the exact characters
function isTrue() {
  if [[ "${@^^}" =~ ^(TRUE$|YES$|Y$|ON$|1$) ]]; then return 0; fi; return 1
}

# installs apt packages if doesn't exist (root user required)
# usage: install_packages curl ca-certificates
function install_packages() {
  if ! dpkg -s "$@" > /dev/null 2>&1; then
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
      apt-get update -y
    fi
    apt-get -y install --no-install-recommends "$@"
  fi
}