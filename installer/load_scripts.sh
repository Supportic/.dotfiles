#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./_config.sh
. "${currentDir}"/_config.sh

function load_scripts(){
  setup_scripts
}

# make sure we have sudo permission before running the script
sudo -v

load_scripts