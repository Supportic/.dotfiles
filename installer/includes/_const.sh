#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

###################################################### env variables
# only available in this script, not permanent

export USER="${USER:-"$(whoami)"}"
export HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"

###################################################### variables

# base dir
# DOTFILES_DIR=$(dirname "${PWD}")
readonly DOTFILES_DIR=$(dirname "$currentDir")

# Templates
readonly TEMPLATE_DIR="${DOTFILES_DIR}/template"

# Timezone
readonly TZ="Europe/Berlin"

# Binaries local directory
readonly LOCAL_BIN_DIR="${HOME}/bin"

# Scripts local directory
readonly LOCAL_SCRIPTS_DIR="${LOCAL_BIN_DIR}/scripts"

# Fonts local directory
readonly LOCAL_FONTS_DIR="${HOME}/.fonts"

# check if in WSL (every docker container created from WSL regardless of the base image)
IN_WSL=false
if [[ -n "${WSL_DISTRO_NAME-}" ]] || (uname -r | grep -qiF 'microsoft'); then
	IN_WSL=true
fi
