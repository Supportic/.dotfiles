#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# User environment (HOME, USER, GROUP) are set by _user_info.sh
# This file defines path constants that depend on the user environment

###################################################### variables

# base dir
export DOTFILES_DIR=$(dirname "$currentDir")
readonly DOTFILES_DIR

# Templates
export TEMPLATE_DIR="${DOTFILES_DIR}/template"
readonly TEMPLATE_DIR

# Timezone
export TZ="Europe/Berlin"
readonly TZ

# Binaries local directory
export LOCAL_BIN_DIR="${INVOKING_HOME}/bin"
readonly LOCAL_BIN_DIR

# Scripts local directory
export LOCAL_SCRIPTS_DIR="${LOCAL_BIN_DIR}/scripts"
readonly LOCAL_SCRIPTS_DIR

# Fonts local directory
export LOCAL_FONTS_DIR="${INVOKING_HOME}/.fonts"
readonly LOCAL_FONTS_DIR

# check if in WSL (every docker container created from WSL regardless of the base image)
export IN_WSL=false
if [[ -n "${WSL_DISTRO_NAME-}" ]] || (uname -r | grep -qiF 'microsoft'); then
	IN_WSL=true
fi
readonly IN_WSL

