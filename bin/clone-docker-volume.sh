#!/bin/bash

# check if docker volume exists
function volumeExists(){
  docker volume inspect "$@" > /dev/null 2>&1
  # was last command successful. Answer is 0 which means 'yes'
  [ "$?" != "0" ] && return 1

  return 0
}

function main(){
  local programname=
  programname=$(basename ${0})
  local usage=
  usage="Usage: ${programname} <OLD_VOLUME_NAME> <NEW_VOLUME_NAME>"

  # check whether user had supplied -h or --help
  if [[ $@ == "--help" ||  $@ == "-h" ]]; then
    echo "This script clones an existing docker volume via an alpine image."
    echo -e "List all available docker volumes: \"docker volume ls\"\n"
    echo "${usage}"
    exit 0
  elif [ $# == 0 ] || [ -z $2 ]; then
    echo -e "Arguments are missing!\n"
    echo "${usage}"
    exit 0
  fi

  if ! volumeExists "$1" ; then
    echo "The source volume \"$1\" does not exist."
    exit 1
  fi

  if ! volumeExists "$2" ; then
    echo "The destination volume \"$2\" does not exist."
    while true; do
      read -p "Would you like to create it? [y/n] " answer
      case $answer in
          [Yy]* )
          echo "Creating destination volume \"$2\" ...";
          docker volume create --name "$2" > /dev/null 2>&1  && echo "Volume $2 successfully created.";
          break;;
          [Nn]* )
          exit 0
          ;;
          * )
          echo "Please answer [y]es or [n]o."
          ;;
      esac
	  done
  else
    echo "The destination volume \"$2\" already exists."
    echo "Please delete it first: \"docker volume rm $2\""
    exit 1
  fi

  # copy the stuff
  echo "Copying data from source volume \"$1\" to destination volume \"$2\" ..."
  docker run --rm \
    --name clonevolume \
          -it \
          -v "$1":/from:ro \
          -v "$2":/to \
          alpine ash -c "cd /from ; cp -a . /to"
  echo "Done copying data from source volume \"$1\" to destination volume \"$2\"."
}

args=${@:-""}

main ${args}

