#!/bin/bash

# call functions from terminal: 
# bash -c ". ~/.dotfiles/scripts/bash/misc.sh && sudoIf ls"

# general: check if command is defined on the system or in the current script as function
function command_exists() {
  [ ! -z "$(command -v "${1:-}")" ]
}
# specific: is the command defined in the current script
function script_command_exists() {
  # appended double quote to make sure we do get a string
  # if $1 is not a known command, type does not output anything
  [ `type -t ${1:-}`"" == 'function' ]
}
# specific: is the command defined on the system
function system_command_exists() {
  [ ! -z $(which "${1:-}") ]
}
function package_exists() {
  local status="$(dpkg-query --show --showformat='${db:Status-Status}' "${1:-}" 2>&1)"
  [ $? -eq 0 ] && [ "${status}" = "installed" ]
}

# use sudo if current user is not root
# usage: sudoIf groupadd ...
function sudoIf() { if [ "$(id -u)" -ne 0 ]; then sudo "$@"; else "$@"; fi }

# regardless of capitalisation
# $ limits to the exact characters
function isTrue() {
  if [[ "${@^^}" =~ ^(TRUE$|YES$|Y$|ON$|1$) ]]; then return 0; fi; return 1
}

# installs apt packages if doesn't exist (root permissions required)
# usage: install_packages curl ca-certificates
function install_packages() {
  if ! dpkg -s $@ >/dev/null 2>&1; then
    if [ "$(find "/var/lib/apt/lists" -mindepth 1 -type d,f | wc -l)" = "0" ]; then
      sudo apt-get update
    fi
    sudo DEBIAN_FRONTEND="noninteractive" apt-get -y install --no-install-recommends $@
  fi
}

# checks if string $1 is in $2
function startswith() { case $2 in "$1"*) true;; *) false;; esac; }