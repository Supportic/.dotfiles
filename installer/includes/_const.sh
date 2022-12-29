#!/bin/bash
set -euo pipefail

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

###################################################### env variables
# only available in this script, not permanent

export USER="${USER:-"$(whoami)"}"

###################################################### variables

# base dir
# DOTFILES_DIR=$(dirname "${PWD}")
DOTFILES_DIR=$(dirname "$dir")
readonly DOTFILES_DIR

# Templates
TEMPLATE_DIR="${DOTFILES_DIR}/template"
readonly TEMPLATE_DIR

# Timezone
TZ="Europe/Berlin"
readonly TZ

# Binaries local directory
LOCAL_BIN_DIR="${HOME}/bin"
readonly LOCAL_BIN_DIR

# Scripts local directory
LOCAL_SCRIPTS_DIR="${LOCAL_BIN_DIR}/scripts"
readonly LOCAL_SCRIPTS_DIR

# Fonts local directory
LOCAL_FONTS_DIR="${HOME}/.fonts"
readonly LOCAL_FONTS_DIR

# check if in WSL (every docker container created from WSL regardless of the base image)
IN_WSL=false
if [[ -n "${WSL_DISTRO_NAME-}" ]] || (uname -r | grep -qiF 'microsoft'); then
	IN_WSL=true
fi
