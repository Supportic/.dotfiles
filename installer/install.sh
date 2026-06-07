#!/bin/bash
set -euo pipefail

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./includes/_functions.sh
. "${currentDir}"/includes/_functions.sh

function check_preconditions() {
  isRoot && die "Please execute script as user with sudo permissions."

  if isFalse "${nointeractive}"; then
    info "This script will configure your Linux machine."
    read -rep $'Do you want to continue? [y/n]: ' canStart
    ([ -z "${canStart}" ] || ! isTrue "$canStart") && die "Script exited.";
    print_info_banner "Setting up Linux...\nHOME=${HOME} | USER=${USER}"
  fi

  ask_sudo

  local packages=("")
  local packagesToInstall=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && ! package_exists "${package}" && packagesToInstall="${packagesToInstall} ${package}"
  done

  if [ -n "${packagesToInstall}" ]; then
    install_packages "${packagesToInstall}"
  fi
}

function install_main() {
  if isTrue "${should_install_essentials}"; then
    bash "${currentDir}"/essentials.sh
  fi

  # create directory and symlinks with user permissions 
  if isTrue "${should_create_symlinks}"; then
    bash "${currentDir}"/sync.sh
  fi

  if isTrue "${should_install_tools}"; then
    bash "${currentDir}"/tools.sh
  fi
}

check_preconditions

# UNIX timestamp concatenated with nanoseconds
start="$(date +%s%N)"
install_main
end="$(date +%s%N)"
difference="$((end-start))"

success "Installation Complete\n"
log "script took: %s" "$(displaytime ${difference})"
