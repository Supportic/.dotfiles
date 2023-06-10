#!/bin/bash
set -euo pipefail
# set -x

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

. "${currentDir}"/_config.sh

sudo -v

# test things here

exclude_ext=(git)

for pluginDir in ~/.oh-my-zsh/plugins/*; do
  pluginDirName="$(basename "${pluginDir}")"
  # NOTE: invert by removing !
  if [ -d "${pluginDir}" ] && [[ ! "${exclude_ext[*]}" =~ ${pluginDirName} ]]; then
    echo "${pluginDir}"
  fi
done