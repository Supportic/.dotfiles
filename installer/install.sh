#!/bin/bash
set -euo pipefail

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./_config.sh
. "${currentDir}"/_config.sh

function check_preconditions() {
  [ "$(id -u)" -ne 0 ] && die "Please execute script with sudo permissions."

  info "This script will configure your Linux machine."
  if isFalse "${nointeractive}"; then
    read -rep $'Do you want to continue? [y/n]: ' canStart
    ([ -z "${canStart}" ] || ! isTrue "$canStart") && echo "Stopped: script exited." && exit;
    print_info_banner "Setting up Linux..."
  fi
  
  local packages=("")
  local install=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && [ ! $(dpkg -s "${package}" >/dev/null 2>&1) ] && install="${install} ${package}"
  done

  [ -n "${install}" ] && install_packages "${install}"
}

function install_main() {
  if isTrue "${install_essentials}"; then
    sudo "${currentDir}"/essentials.sh
  fi

  # _config.sh
  symlink_git_config
  symlink_ssh_config

  if isTrue "${install_symlinks}"; then
    sudo "${currentDir}"/sync.sh
  fi

  if isTrue "${install_tools}"; then
    sudo "${currentDir}"/tools.sh
  fi

  # configure_git
  command_exists "zsh" && zsh -c "source ~/.zshrc"
}

check_preconditions

# UNIX timestamp concatenated with nanoseconds
start=$(date +%s%N)
install_main
end=$(date +%s%N)
difference="$((end-start))"

printf "Installation Complete\n"
printf "script took: %s\n" "$(displaytime ${difference})"
