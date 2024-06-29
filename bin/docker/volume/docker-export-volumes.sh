#!/bin/bash

[ -z "$(command -v docker)" ] && echo "Error: Docker not available" && exit 2;

function main() {
  local programname=
  programname=$(basename ${0})
  local usage=
  usage="Usage: ${programname} [<EXPORT_DIRECTORY>=.volumes]"

  # check whether user had supplied -h or --help
  if [[ $@ == "--help" ||  $@ == "-h" ]]; then
    printf "This script exports all volumes into a directory. It creates the directory for you.\n"
    printf "${usage}\n"
    exit 0
  fi

  local EXPORT_DIRECTORY="${1:-.volumes}"

  if [ -d "${EXPORT_DIRECTORY}" ]; then
    echo "Directory ${EXPORT_DIRECTORY} already exists. Exiting."; exit 1
  else
    mkdir -p "${EXPORT_DIRECTORY}"
  fi

  VOLUMES=$(docker volume ls -q | tr '\n' ' ')
  VOLUMES_LIST=($VOLUMES)
  file_count=${#VOLUMES_LIST[@]}
  import_count=0;
  for V in $VOLUMES ; do
    echo "Exporting volume $V";
    # init is important to receive SIGTERM signals
    docker run --rm --init -v "${V}:/data" -v "${PWD}/${EXPORT_DIRECTORY}:/backup" busybox tar cvzf "/backup/${V}.tar.gz" /data

    success=$?
    [ $success -eq 0 ] && import_count=$((import_count+1)); echo "Exported volume $V"
  done

  printf "$import_count/$file_count volumes exported to ${PWD}/${EXPORT_DIRECTORY}\nSetting up ownership to current user.\n"

  sudo -v
  tar_gz_files=($(find "${EXPORT_DIRECTORY}" -type f -name "*.tar.gz"))
  for V in $tar_gz_files ; do
    sudo chown -R "$(id -u):$(id -g)" "${V}"
  done

  printf "Export complete.\n"; exit 0
}

args="${@:-}"

main ${args}
