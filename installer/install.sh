#!/bin/bash
set -euo pipefail

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./includes/_functions.sh
. "${currentDir}"/includes/_functions.sh

function check_preconditions() {
  ! isRoot && die "Please execute script with sudo permissions."

  if isFalse "${nointeractive}"; then
    info "This script will configure your Linux machine."
    read -rep $'Do you want to continue? [y/n]: ' canStart
    ([ -z "${canStart}" ] || ! isTrue "$canStart") && die "Script exited.";
    print_info_banner "Setting up Linux...\nHOME=${HOME} | USER=${USER}"
  fi

  local packages=("")
  local packagesToInstall=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && ! package_exists "${package}" && packagesToInstall="${packagesToInstall} ${package}"
  done

  if [ -n "${packagesToInstall}" ]; then
    install_packages "${packagesToInstall}"
  fi
}

# -u with user ownership, -E preserve env variables
function install_main() {
  if isTrue "${should_install_essentials}"; then
    sudo -E USER="${USER}" bash "${currentDir}"/essentials.sh
  fi

  # create directory and symlinks with user permissions 
  if isTrue "${should_create_symlinks}"; then
    sudo -u "${USER}" -E USER="${USER}" bash "${currentDir}"/sync.sh
  fi

  if isTrue "${should_install_tools}"; then
    sudo -E USER="${USER}" bash "${currentDir}"/tools.sh
  fi
}

check_preconditions

# UNIX timestamp concatenated with nanoseconds
start="$(date +%s%N)"
install_main
end="$(date +%s%N)"
difference="$((end-start))"

success "Installation Complete\n"
log "script took: %s\n" "$(displaytime ${difference})"
