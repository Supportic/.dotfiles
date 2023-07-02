#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./includes/_functions.sh
. "${currentDir}"/includes/_functions.sh

function check_preconditions() {
  isRoot && die "Please execute script without sudo permissions."

  local packages=("")
  local packagesToInstall=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && ! package_exists "${package}" && packagesToInstall="${packagesToInstall} ${package}"
  done

  if [ -n "${packagesToInstall}" ]; then
    install_packages "${packagesToInstall}"
  fi
}

function create_symlinks() {
  # _functions.sh
  symlink_git_config
  symlink_zsh_config
  symlink_ssh_config
  symlink_scripts

  configure_git
  command_exists "zsh" && zsh -c "source ${HOME}/.zshrc"
}

check_preconditions
create_symlinks
