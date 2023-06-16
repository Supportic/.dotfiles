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

function install_symlinks() {
  # _config.sh
  symlink_scripts
}

check_preconditions
install_symlinks
