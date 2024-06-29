#!/bin/bash

[ -z "$(command -v docker)" ] && echo "Error: Docker not available" && exit 2;

# check if docker volume exists
function volumeExists() {
  VOLUME_NAME="${1:-}"
  [ -z "$VOLUME_NAME" ] && echo "Error[fn:volumeExists] requires parameter" && exit 1

  docker volume ls -q | grep -qe ^"${VOLUME_NAME}"$

  success=$?
  [ $success -eq 0 ] && return 0 || return 1
}

function main() {
  local programname=
  programname=$(basename ${0})
  local usage=
  usage="Usage: ${programname} [<IMPORT_DIRECTORY>=.volumes]"

  # check whether user had supplied -h or --help
  if [[ $@ == "--help" ||  $@ == "-h" ]]; then
    printf "This script imports all volumes.tar.gz files of a directory.\n"
    printf "${usage}\n"
    exit 0
  fi

  local IMPORT_DIRECTORY="${1:-.volumes}"

  if [ ! -d "${IMPORT_DIRECTORY}" ]; then
    echo "Directory ${IMPORT_DIRECTORY} does not exist. Exiting."; exit 1
  fi

  tar_gz_files=$(find "${IMPORT_DIRECTORY}" -type f -name "*.tar.gz")
  tar_gz_files_list=($tar_gz_files)
  file_count=${#tar_gz_files_list[@]}
  import_count=0;
  
  for V in $tar_gz_files ; do

    filepath=$(basename -- "$V")
    filename=$(echo $filepath | awk -F. '{ print $1 }')

    if volumeExists "${filename}"; then
      printf "Volume ${filename} already exists.\n"
      continue
    fi

    echo "Importing volume $filename";
    # init is important to receive SIGTERM signals
    docker run --rm --init -v "${filename}:/data" -v "${PWD}/${IMPORT_DIRECTORY}:/backup-dir" busybox /bin/sh -c "rm -rf /data/{*,.*}; cd /data && tar xvzf /backup-dir/${filename}.tar.gz --strip 1" > /dev/null 2>&1

    success=$?
    [ $success -eq 0 ] && import_count=$((import_count+1))

  done

  printf "$import_count/$file_count volumes imported.\nImport complete.\n"; exit 0
}

args="${@:-}"

main ${args}

