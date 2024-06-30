#!/bin/bash

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker not available"
  exit 2
fi

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
    printf "This script imports a volume.tar.gz file of the current directory.\n"
    printf "${usage}\n"
    exit 0
  elif [ $# -ne 1 ]; then
    printf "Insufficient arguments!\n\n"
    printf "${usage}\n"
    exit 0
  fi

  local VOLUME_NAME="${1:-}"

  if [ ! -f "${VOLUME_NAME}.tar.gz" ]; then
    printf "File ${VOLUME_NAME}.tar.gz does not exist in current directory. \n"
    exit 1;
  fi

  if volumeExists "${VOLUME_NAME}"; then
    echo "Volume ${VOLUME_NAME} already exists."; exit 1;
  fi

  echo "Importing volume $VOLUME_NAME";
  # init is important to receive SIGTERM signals
  docker run --rm --init -v "${VOLUME_NAME}:/data" -v "${PWD}:/backup-dir" busybox /bin/sh -c "rm -rf /data/{*,.*}; cd /data && tar xvzf /backup-dir/${VOLUME_NAME}.tar.gz --strip 1"

  local success=$?
  [ $success -ne 0 ] && printf "Import failed.\n" && exit 1;

  printf "Volume imported.\nExport complete.\n"; exit 0
}

args="${@:-}"

main ${args}
