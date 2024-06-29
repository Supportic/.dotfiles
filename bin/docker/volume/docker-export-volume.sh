#!/bin/bash

[ -z "$(command -v docker)" ] && echo "Error: Docker not available" && exit 2;

# check if docker volume exists
function volumeExists() {
  local VOLUME_NAME="${1:-}"
  [ -z "$VOLUME_NAME" ] && echo "Error[fn:volumeExists] requires parameter" && exit 1

  docker volume ls -q | grep -qe ^"${VOLUME_NAME}"$

  local success=$?
  [ $success -eq 0 ] && return 0 || return 1
}

function main() {

  local programname=
  programname=$(basename ${0})
  local usage=
  usage="Usage: ${programname} <VOLUME_NAME>"

  # check whether user had supplied -h or --help
  if [[ $@ == "--help" ||  $@ == "-h" ]]; then
    printf "This script exports a volume into the current directory.\n"
    printf "${usage}\n"
    exit 0
  elif [ $# -ne 1 ]; then
    printf "Insufficient arguments!\n\n"
    printf "${usage}\n"
    exit 0
  fi

  local VOLUME_NAME="${1:-}"

  if [ -f "${VOLUME_NAME}.tar.gz" ]; then
    echo "File ${VOLUME_NAME}.tar.gz already exists."; exit 1;
  fi

  if ! volumeExists "${VOLUME_NAME}"; then
    echo "Volume ${VOLUME_NAME} does not exist."; exit 1;
  fi

  echo "Exporting volume $VOLUME_NAME";
  # init is important to receive SIGTERM signals
  docker run --rm --init -v "${VOLUME_NAME}:/data" -v "${PWD}:/backup" busybox tar cvzf "/backup/${VOLUME_NAME}.tar.gz" /data

  local success=$?
  [ $success -ne 0 ] && printf "Export failed.\n" && exit 1;

  printf "Volume exported to ${PWD}\nSetting up ownership to current user.\n"
  sudo -v
  sudo chown -R $(id -u):$(id -g) "${VOLUME_NAME}.tar.gz"
  printf "Export complete.\n"; exit 0
}

args="${@:-}"

main ${args}
