#!/bin/bash
set -euo pipefail

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./_config.sh
. "${dir}"/_config.sh

function config_main(){
  setup_git
  setup_zsh
  setup_ssh
  setup_scripts
}

# make sure we have sudo permission before running the script
sudo -v

config_main
configure_settings