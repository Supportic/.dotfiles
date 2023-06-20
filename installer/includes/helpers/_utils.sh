#!/bin/bash
set -euo pipefail

# call functions from terminal: 
# bash -c ". ~/.dotfiles/installer/includes/_utils.sh && print_info_banner 'hello world'"

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

function isRoot(){
  [ "${EUID:-$(id -u)}" -eq 0 ]
}

# installs apt packages if doesn't exist (root permissions required)
# usage: install_packages curl ca-certificates
function install_packages() {
  if ! dpkg -s $@ >/dev/null 2>&1; then
    if [ "$(find "/var/lib/apt/lists" -mindepth 1 -type d,f | wc -l)" = "0" ]; then
      sudo apt-get update
    fi
    sudo DEBIAN_FRONTEND="noninteractive" apt-get -y install --no-install-recommends $@
  fi
}
# make sure that packages or programs are installed before use
# usage: ensure_packages locales tzdata
function ensure_packages() {
  local packages=($@)
  local install=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && [ ! "$(dpkg -s "${package}" >/dev/null 2>&1)" ] && install="${install} ${package}"
  done

  [ -n "${install}" ] && install_packages "${install}"
}

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
  echo "${MS:(-3)} milliseconds\n"
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

# colors https://stackoverflow.com/a/5947802
# Print log message
function log() {
  printf "$*\n"
}
# Print error message (redirect output to STDERR)
function failure() {
  local RED='\033[00;31m'
  local RESTORE='\033[0m'
  printf >&2 "${RED}$*${RESTORE}\n"
}
# Print success message to STDERR
function success() {
  local BGREEN='\033[01;32m'
  local RESTORE='\033[0m'
  printf "${BGREEN}$*${RESTORE}\n"
}
# Print info message to STDERR
function info() {
  local BLUE='\033[00;34m'
  local RESTORE='\033[0m'
  printf "${BLUE}$*${RESTORE}\n"
}
# Print error message to STDERR and exit
function die() {
  failure "$*"
  exit 1
}
function print_info_banner() {
  function str_length() {
    local strLen oLang="${LANG-}" oLcAll="${LC_ALL-}"
    LANG="C.UTF-8" LC_ALL="C.UTF-8"
    strLen="${#1}"
    LANG="${oLang}" LC_ALL="${oLcAll}"
    echo ${strLen}
  }
  function repeat() { num="${2-}"; printf -- "$1%.0s" $(seq 1 $num); }
  function multiline_max_length(){
    local msg maxMsgLength line lines lineLength

    # required to preserve newline characters 
    msg=$(echo -e "$1")
    maxMsgLength="0"

    readarray -t lines <<<"$msg"
    for line in "${lines[@]}"; do
      lineLength=$(str_length "__${line}__")
      if [ "$lineLength" -gt "$maxMsgLength" ];then
        maxMsgLength="${lineLength}"
      fi
    done

    echo $maxMsgLength
  }
  function multiline_prepend_symbol(){
    local msg symbol newMsg

    msg=$(echo -e "$1")
    symbol="$2"
    newMsg=""

    readarray -t lines <<<"$msg"
    for line in "${lines[@]}"; do
      newMsg="${newMsg}\n${symbol} ${line}"
    done

    echo "$newMsg"
  }

  local msg symbol maxMsgLength divider
  msg="$1"
  symbol="#"
  maxMsgLength=$(multiline_max_length "${msg}")

  msg=$(multiline_prepend_symbol "${msg}" "${symbol}")
  divider=$(repeat "${symbol}" "${maxMsgLength}")

  info "$(printf "\n%s${msg} \n%s" "${divider}" "${divider}")\n"
}

function extract() {
  system_command_exists "unzip" || die "Please install unzip."

  local archive="${1-}"
  local extract_to="${2-}"

  unzip -qo "${archive}" -d "${extract_to}" >/dev/null 2>&1
}

# Remove files or directories
function cleanup() {
  for item in "$@"; do
    if [ -f "${item}" ]; then
      unlink "${item}" || die "Unable to unlink: ${item}"
    elif [ -d "${item}" ]; then
      rm -r "${item}" || die "Unable to remove: ${item}"
    fi
  done
}

# Get item from latest json release data
# when there are multiple occurances of that json key => put parenthesis around the call to create an array
# var=($(get_json_value "key" "$(cat "${file}")")) => "${var[2]}"
function get_json_value() {
  local key="${1-}"
  local read_from="${2-}"
  
  # input is file or string
  if [ -f "${read_from}" ]; then
    value=$(awk -F '"' "/${key}/ {print \$4}" "${read_from}")
  else
    value=$(echo "${read_from}" | awk -F '"' "/${key}/ {print \$4}")
  fi
  
  echo "${value}"
}

# general: check if command is defined on the system or in the current script as function
function command_exists() {
  [ ! -z "$(command -v "${1:-}")" ]
}
# specific: is the command defined in the current script
function script_command_exists() {
  # appended double quote to make sure we do get a string
  # if $1 is not a known command, type does not output anything
  [ `type -t ${1:-}`"" == 'function' ]
}
# specific: is the command defined on the system
function system_command_exists() {
  [ ! -z $(which "${1:-}") ]
}
function package_exists() {
  local status="$(dpkg-query --show --showformat='${db:Status-Status}' "${1:-}" 2>&1)"
  [ $? -eq 0 ] && [ "${status}" = "installed" ]
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
  system_command_exists "curl" || die "Please install curl."

  command curl -fsSL --retry 3 "$@"
}
