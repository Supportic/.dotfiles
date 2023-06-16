#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./_config.sh
. "${currentDir}"/_config.sh


function check_preconditions() {
  [ "$(id -u)" -ne 0 ] && die "Please execute script with sudo permissions."
  
  local packages=("")
  local install=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && [ ! "$(dpkg -s "${package}" >/dev/null 2>&1)" ] && install="${install} ${package}"
  done

  [ -n "${install}" ] && install_packages "${install}"
}

function config_main(){
  symlink_git_config
  symlink_zsh_config
  symlink_ssh_config
  symlink_scripts

  configure_git
  command_exists "zsh" && zsh -c "source ~/.zshrc"
}

check_preconditions
config_main