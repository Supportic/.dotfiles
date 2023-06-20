#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

if [ "$(id -u)" -eq 0 ] && [ "${SUDO_USER}" != "root" ]; then
  export HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
  export USER="${SUDO_USER}"
  export GROUP="$(id -gn ${SUDO_USER})"
elif [ "$(id -u)" -ne 0 ] && [ -z "${USER:-}" ]; then
  export USER="$(whoami)"
  export HOME="$(getent passwd "${USER}" | cut -d: -f6)"
  export GROUP="$(id -gn ${USER})"
fi

###################################################### variables

# base dir
# DOTFILES_DIR=$(dirname "${PWD}")
export DOTFILES_DIR=$(dirname "$currentDir")
readonly DOTFILES_DIR

# Templates
export TEMPLATE_DIR="${DOTFILES_DIR}/template"
readonly TEMPLATE_DIR

# Timezone
export TZ="Europe/Berlin"
readonly TZ

# Binaries local directory
export LOCAL_BIN_DIR="${HOME}/bin"
readonly LOCAL_BIN_DIR

# Scripts local directory
export LOCAL_SCRIPTS_DIR="${LOCAL_BIN_DIR}/scripts"
readonly LOCAL_SCRIPTS_DIR

# Fonts local directory
export LOCAL_FONTS_DIR="${HOME}/.fonts"
readonly LOCAL_FONTS_DIR

# check if in WSL (every docker container created from WSL regardless of the base image)
export IN_WSL=false
if [[ -n "${WSL_DISTRO_NAME-}" ]] || (uname -r | grep -qiF 'microsoft'); then
	IN_WSL=true
fi
readonly IN_WSL

