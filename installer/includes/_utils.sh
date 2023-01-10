#!/bin/bash
set -euo pipefail

# call functions from terminal: 
# bash -c ". ~/.dotfiles/installer/includes/_utils.sh && print_info 'hello world'"

# $1 = time difference in ms
function displaytime() {
  # Milliseconds
  local ms="$(($1/1000000))"
  # Seconds
  local s="$(($1/1000000000))"

  # Milliseconds (2 milliseconds correction)
  local MS="$((ms-2))"
  # Seconds
  local S="$((s%60))"
  local M="$((s/60%60))"
  local H="$((s/60/60%24))"
  local D="$((s/60/60/24))"
  (( $D > 0 )) && printf '%02d days ' $D
  (( $H > 0 )) && printf '%02d hours ' $H
  (( $M > 0 )) && printf '%02d minutes ' $M
  (( $S > 0 )) && printf '%02d seconds ' $S
  (( $D > 0 || $H > 0 || $M > 0 || $S > 0 )) && printf 'and '
  printf '%d milliseconds\n' "${MS:(-3)}"
}

# regardless of capitalisation
# $ limits to the exact characters
function isTrue() {
  if [[ "${@^^}" =~ ^(TRUE$|YES$|Y$|ON$|1$) ]]; then
    return 0;
  fi
  return 1
}

function isFalse() {
  if [[ "${@^^}" =~ ^(FALSE$|NO$|N$|OFF$|0$) ]]; then
    return 0;
  fi
  return 1
}

# checks if current or a given user is in group
# usage:
# if ingroup $1; then
#   echo 'yes'
# else
#   echo 'no'
# fi
function ingroup(){ [[ " `id -Gn ${2-}` " == *" $1 "* ]]; }

# Print error message to STDERR and exit
function die() {
  local RED=$(echo -en '\033[00;31m')
  local RESTORE=$(echo -en '\033[0m')
  echo >&2 "${RED}$*${RESTORE}"
  exit 1
}

function extract() {

  local archive="${1}"
  local extract_to="${2}"

  unzip -qo "${archive}" -d "${extract_to}" >/dev/null 2>&1
}

# Remove temporary file
function cleanup() {
  if [ -f "${1}" ]; then
    unlink "${1}" || die "Unable to unlink: ${1}"
  else
    rm -r "${1}" || die "Unable to remove: ${1}"
  fi
}

# Get item from latest release data
function get_item() {
  local item="${1}"
  local read_from="${2}"
  awk -F '"' "/${item}/ {print \$4}" "${read_from}"
}

# check if a binary is installed
function command_exists() {
  [ ! -z "$(command -v $1)" ]
}

function str_length() {
    local strLen oLang=${LANG-} oLcAll=${LC_ALL-}
    LANG=C.UTF-8 LC_ALL=C.UTF-8
    strLen=${#1}
    LANG=${oLang} LC_ALL=${oLcAll}
    echo ${strLen}
}

function repeat() { num="${2-}"; printf -- "$1%.0s" $(seq 1 $num); }

function print_info() {
  msg="$1"
  msgLength=$(str_length "__$1__")
  divider=$(repeat '#' ${msgLength})
  
  printf "\n%s\n# ${msg} \n%s\n\n" "${divider}" "${divider}"
}

# Download URL
function download() {

  local url="${1-}"
  local save_as="${2-}"

  # wget -O-
  if [ -z "${save_as}" ]; then
	  curl "${url}" || die "Unable to download: ${url}"
  else
	  curl -o "${save_as}" "${url}" || die "Unable to download: ${url}"
  fi
}

function curl() {
  command curl -fsSL --retry 3 "$@"
}

# function wget() {
# 	command wget --no-verbose --timeout=10 --show-progress --progress=bar:force:noscroll "$@"
# }