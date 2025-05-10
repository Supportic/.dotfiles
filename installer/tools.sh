#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./includes/_functions.sh
. "${currentDir}"/includes/_functions.sh

function check_preconditions() {
  ! isRoot && die "Please execute script with sudo permissions."
  
  local packages=("curl" "unzip" "tar" "bzip2" "ca-certificates")
  local packagesToInstall=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && ! package_exists "${package}" && packagesToInstall="${packagesToInstall} ${package}"
  done

  if [ -n "${packagesToInstall}" ]; then
    install_packages "${packagesToInstall}"
  fi
}

# exa better ls (remove: sudo rm -f /usr/local/bin/eza)
function install_eza() {
  print_info_banner "Installing eza"
  local LATEST_RELEASE_URL="https://api.github.com/repos/eza-community/eza/releases/latest"

  local LATEST_INFO_TEMPFILE EZA_TEMPFILE EZA_VERSION BROWSER_URL
  EZA_TEMPFILE=$(mktemp)
  LATEST_INFO_TEMPFILE=$(mktemp)

  log "Downloading latest release info: ${LATEST_RELEASE_URL}"
  download "${LATEST_RELEASE_URL}" "${LATEST_INFO_TEMPFILE}"
  EZA_VERSION=$(get_json_value "tag_name" "${LATEST_INFO_TEMPFILE}")
  log "Latest eza version: ${EZA_VERSION}"
  BROWSER_URL=($(get_json_value "browser_download_url" "${LATEST_INFO_TEMPFILE}" true))
  log "Downloading eza archive: ${BROWSER_URL[12]}"

  # https://github.com/eza-community/eza/releases/download/v0.18.15/eza_x86_64-unknown-linux-musl.zip
  download "${BROWSER_URL[12]}" "${EZA_TEMPFILE}"

  # -> /usr/local/bin/eza
  if ! sudo unzip -qo "${EZA_TEMPFILE}" eza -d /usr/local/bin; then
    cleanup "${LATEST_INFO_TEMPFILE}" "${EZA_TEMPFILE}"
    die "Could not unzip eza archive ${EZA_TEMPFILE}. Cleaning up tempfiles..."
  else
    log "Cleaning up eza tempfiles..."
    cleanup "${LATEST_INFO_TEMPFILE}" "${EZA_TEMPFILE}"
    sudo chown "${USER}":"${GROUP}" "/usr/local/bin/eza"
    success "eza installed."
  fi
}

# bat better cat (remove: sudo dpkg -r bat)
function install_bat() {
  print_info_banner "Installing bat"
  local LATEST_RELEASE_URL="https://api.github.com/repos/sharkdp/bat/releases/latest"

  local LATEST_INFO_TEMPFILE BAT_TEMPFILE BAT_VERSION BROWSER_URL
  BAT_TEMPFILE=$(mktemp)
  LATEST_INFO_TEMPFILE=$(mktemp)

  log "Downloading latest release info: ${LATEST_RELEASE_URL}"
  download "${LATEST_RELEASE_URL}" "${LATEST_INFO_TEMPFILE}"
  BAT_VERSION=$(get_json_value "tag_name" "${LATEST_INFO_TEMPFILE}")
  log "Latest bat version: ${BAT_VERSION}"
  BROWSER_URL=($(get_json_value "browser_download_url" "${LATEST_INFO_TEMPFILE}" true))
  log "Downloading bat .deb file: ${BROWSER_URL[13]}"
  
  # https://github.com/sharkdp/bat/releases/download/v0.23.0/bat_0.23.0_amd64.deb
  download "${BROWSER_URL[13]}" "${BAT_TEMPFILE}"

  # /dev/null 2>&1
  if ! sudo dpkg -i "${BAT_TEMPFILE}"; then
    cleanup "${LATEST_INFO_TEMPFILE}" "${BAT_TEMPFILE}"
    die "Could not dpkg install bat ${BAT_TEMPFILE}. Cleaning up tempfiles..."
  else
    log "Cleaning up exa tempfiles..."
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

  log "Downloading latest release info: ${LATEST_RELEASE_URL}"
  download "${LATEST_RELEASE_URL}" "${LATEST_INFO_TEMPFILE}"
  BTOP_VERSION=$(get_json_value "tag_name" "${LATEST_INFO_TEMPFILE}")
  log "Latest btop version: ${BTOP_VERSION}"
  BROWSER_URL="https://github.com/aristocratos/btop/releases/download/${BTOP_VERSION}/btop-x86_64-linux-musl.tbz"

  log "Downloading btop archive: ${BROWSER_URL}"
  download "${BROWSER_URL}" "${BTOP_TEMPFILE}"

  sudo tar -xjf "${BTOP_TEMPFILE}" -C "${BTOP_TEMPDIR}"
  sudo cp -pu "${BTOP_TEMPDIR}"/btop/bin/btop /usr/local/bin

  log "Cleaning up btop  tempfiles..."
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
  ! command_exists "exa" && install_eza || info "exa already installed. Skipped..."
  ! command_exists "bat" && install_bat || info "bat already installed. Skipped..."
  ! command_exists "btop" && install_btop || info "btop already installed. Skipped..."
  ! command_exists "pigz" && install_pigz || info "pigz already installed. Skipped..."
  ! command_exists "trash" && install_trash || info "trash already installed. Skipped..."
}

check_preconditions
sudo -v
install_tools
