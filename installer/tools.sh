#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./_config.sh
. "${currentDir}"/_config.sh


function check_preconditions() {
  [ "$(id -u)" -ne 0 ] && die "Please execute script with sudo permissions."
  
  local packages=("curl" "unzip" "tar" "bzip2" "ca-certificates")
  local install=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && [ ! "$(dpkg -s "${package}" >/dev/null 2>&1)" ] && install="${install} ${package}"
  done

  [ -n "${install}" ] && install_packages "${install}"
}


# exa better ls (remove: sudo rm -f /usr/local/bin/exa)
function install_exa() {
  print_info_banner "Installing exa"
  local LATEST_RELEASE_URL="https://api.github.com/repos/ogham/exa/releases/latest"

  local LATEST_INFO_TEMPFILE EXA_TEMPFILE EXA_VERSION BROWSER_URL
  EXA_TEMPFILE=$(mktemp)
  LATEST_INFO_TEMPFILE=$(mktemp)

  echo "Downloading latest release info: ${LATEST_RELEASE_URL}"
  download "${LATEST_RELEASE_URL}" "${LATEST_INFO_TEMPFILE}"
  EXA_VERSION=$(get_json_value "tag_name" "${LATEST_INFO_TEMPFILE}")
  echo "Latest exa version: ${EXA_VERSION}"
  BROWSER_URL=($(get_json_value "browser_download_url" "${LATEST_INFO_TEMPFILE}" true))
  echo "Downloading exa archive: ${BROWSER_URL[3]}"

  download "${BROWSER_URL[3]}" "${EXA_TEMPFILE}"

  # -> /usr/local/bin/exa
  if ! sudo unzip -qo "${EXA_TEMPFILE}" bin/exa -d /usr/local; then
    cleanup "${LATEST_INFO_TEMPFILE}" "${EXA_TEMPFILE}"
    die "Could not unzip exa archive ${EXA_TEMPFILE}. Cleaning up tempfiles..."
  else
    echo "Cleaning up exa tempfiles..."
    cleanup "${LATEST_INFO_TEMPFILE}" "${EXA_TEMPFILE}"
    success "exa installed."
  fi
}

# bat better cat (remove: sudo dpkg -r bat)
function install_bat() {
  print_info_banner "Installing bat"
  local LATEST_RELEASE_URL="https://api.github.com/repos/sharkdp/bat/releases/latest"

  local LATEST_INFO_TEMPFILE BAT_TEMPFILE BAT_VERSION BROWSER_URL
  BAT_TEMPFILE=$(mktemp)
  LATEST_INFO_TEMPFILE=$(mktemp)

  echo "Downloading latest release info: ${LATEST_RELEASE_URL}"
  download "${LATEST_RELEASE_URL}" "${LATEST_INFO_TEMPFILE}"
  BAT_VERSION=$(get_json_value "tag_name" "${LATEST_INFO_TEMPFILE}")
  echo "Latest bat version: ${BAT_VERSION}"
  BROWSER_URL=($(get_json_value "browser_download_url" "${LATEST_INFO_TEMPFILE}" true))
  echo "Downloading bat .deb file: ${BROWSER_URL[13]}"
  
  # https://github.com/sharkdp/bat/releases/download/v0.23.0/bat_0.23.0_amd64.deb
  download "${BROWSER_URL[13]}" "${BAT_TEMPFILE}"

  # /dev/null 2>&1
  if ! sudo dpkg -i "${BAT_TEMPFILE}"; then
    cleanup "${LATEST_INFO_TEMPFILE}" "${BAT_TEMPFILE}"
    die "Could not dpkg install bat ${BAT_TEMPFILE}. Cleaning up tempfiles..."
  else
    echo "Cleaning up exa tempfiles..."
    cleanup "${LATEST_INFO_TEMPFILE}" "${BAT_TEMPFILE}"
    success "bat installed."
  fi
}

# btop better top (remove: sudo rm -f /usr/local/bin/btop)
function install_btop() {
  print_info_banner "Installing btop"
  local LATEST_RELEASE_URL="https://api.github.com/repos/aristocratos/btop/releases/latest"

  local LATEST_INFO_TEMPFILE BTOP_TEMPFILE BTOP_TEMPDIR BTOP_VERSION BROWSER_URL
  BTOP_TEMPFILE=$(mktemp)
  BTOP_TEMPDIR=$(mktemp -d)
  LATEST_INFO_TEMPFILE=$(mktemp)

  echo "Downloading latest release info: ${LATEST_RELEASE_URL}"
  download "${LATEST_RELEASE_URL}" "${LATEST_INFO_TEMPFILE}"
  BTOP_VERSION=$(get_json_value "tag_name" "${LATEST_INFO_TEMPFILE}")
  echo "Latest btop version: ${BTOP_VERSION}"
  BROWSER_URL="https://github.com/aristocratos/btop/releases/download/${BTOP_VERSION}/btop-x86_64-linux-musl.tbz"

  echo "Downloading btop archive: ${BROWSER_URL}"
  download "${BROWSER_URL}" "${BTOP_TEMPFILE}"

  sudo tar -xjf "${BTOP_TEMPFILE}" -C "${BTOP_TEMPDIR}"
  sudo cp -pu "${BTOP_TEMPDIR}"/btop/bin/btop /usr/local/bin

  echo "Cleaning up btop  tempfiles..."
  cleanup "${BTOP_TEMPFILE}" "${BTOP_TEMPDIR}" "${LATEST_INFO_TEMPFILE}"
  success "btop installed."
}

# pigz better archive compression than gzip
function install_pigz() {
  print_info_banner "Installing pigz"
  install_packages pigz
  success "pigz installed."
}

# put items in trash instead of removing them
function install_trash() {
  print_info_banner "Installing trash"
  install_packages trash-cli
  success "trash installed."
}

function install_tools() {
  ! command_exists "exa" && install_exa || info "exa already installed. Skipped..."
  ! command_exists "bat" && install_bat || info "bat already installed. Skipped..."
  ! command_exists "btop" && install_btop || info "btop already installed. Skipped..."
  ! command_exists "pigz" && install_pigz || info "pigz already installed. Skipped..."
  ! command_exists "trash" && install_trash || info "trash already installed. Skipped..."
}

check_preconditions
install_tools
