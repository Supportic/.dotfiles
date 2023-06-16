#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./_config.sh
. "${currentDir}"/_config.sh

function check_preconditions() {
  [ "$(id -u)" -ne 0 ] && die "Please execute script with sudo permissions."
  
  local packages=("")
  local install=""
  for package in "${packages[@]}"; do
    ! system_command_exists "${package}" && [ ! "$(dpkg -s "${package}" >/dev/null 2>&1)" ] && install="${install} ${package}"
  done

  [ -n "${install}" ] && install_packages "${install}"
}

# software-properties-common is needed for to use 'add-apt-repository' for GIT, will install python3
# build-essential installs gcc and make
# dnsutils dig and nslookup
# net-tools for ifconfig; iproute2 is the updated one for ip
# lsof deal with ports
function install_base_packages() {
  sudo DEBIAN_FRONTEND="noninteractive" TZ="${TZ}" apt-get -y install \
    software-properties-common \
    build-essential \
    apt-utils \
    fontconfig \
    curl wget \
    zip unzip \
    tree \
    dnsutils \
    net-tools iproute2 \
    lsof
}

# set /etc/localtime and /etc/timezone
function install_timezone() {
  install_packages "locales" "tzdata"

  sudo ln -sfn /usr/share/zoneinfo/"${TZ}" /etc/localtime
  # writes TZ into /etc/timezone
  sudo dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1
}

function install_git() {
  sudo add-apt-repository -y ppa:git-core/ppa
  install_packages "gpg-agent" "git"
}

function install_fonts() {
  if [ ! -d "${LOCAL_FONTS_DIR}" ]; then
    echo "Creating fonts directory: ${LOCAL_FONTS_DIR}"
    mkdir -p "${LOCAL_FONTS_DIR}" >/dev/null 2>&1 || die "Unable to create fonts directory: ${LOCAL_FONTS_DIR}"
  fi

  if [ ! -d "${LOCAL_FONTS_DIR}/JetBrains Mono" ]; then
    # Generate temporary filename
    local LATEST_INFO_TEMPFILE FONTS_TEMPFILE FONT_VERSION BROWSER_URL
    LATEST_INFO_TEMPFILE="$(mktemp)"
    FONTS_TEMPFILE="$(mktemp)"
    # Latest fonts release info in JSON
    local LATEST_RELEASE_URL="https://api.github.com/repos/JetBrains/JetBrainsMono/releases/latest"
    echo "Downloading latest release info: ${LATEST_RELEASE_URL}"
    download "${LATEST_RELEASE_URL}" "${LATEST_INFO_TEMPFILE}"
    FONT_VERSION=$(get_json_value "tag_name" "${LATEST_INFO_TEMPFILE}")
    BROWSER_URL=$(get_json_value "browser_download_url" "${LATEST_INFO_TEMPFILE}")
    echo "Latest fonts version: ${FONT_VERSION}"

    echo "Downloading fonts archive: ${BROWSER_URL}"
    download "${BROWSER_URL}" "${FONTS_TEMPFILE}"
    echo "Extracting fonts: ${LOCAL_FONTS_DIR}"
    extract "${FONTS_TEMPFILE}" "${LOCAL_FONTS_DIR}/JetBrains Mono"

    echo "Cleaning up..."
    cleanup "${LATEST_INFO_TEMPFILE}"
    cleanup "${FONTS_TEMPFILE}"
  fi

  echo "Building fonts cache..."
  fc-cache -f || die "Unable to build fonts cache"
  echo "Fonts have been installed"
}

# cat /etc/default/locale
# https://wiki.archlinux.org/title/locale#LANG:_default_locale
function install_language() {
  local de_locale en_locale de en lang_to_install
  
  lang_to_install=""
  de_locale="de_DE.utf8" en_locale="en_US.utf8"
  de="de_DE.UTF-8" en="en_US.UTF-8"
  # add to language list when lang wasn't found
  ! locale -a | grep "${de_locale}" && lang_to_install+="${de} "
  ! locale -a | grep "${en_locale}" && lang_to_install+="${en}"

  # install when language list is filled
  [ -z "${lang_to_install}" ] || sudo locale-gen ${lang_to_install}
  sudo update-locale \
    # The locale set for this variable will be used for all the LC_* variables that are not explicitly set.
    LANG="${de}" \
    # character set used to display and input text
    LC_CTYPE="${en}" \
    # system messages
    LC_MESSAGES="${en}" \
    # alphabetical order for strings (e.g. file names)
    LC_COLLATE="${en}"
}

function install_ssh() {
  install_packages "openssh-client" "keychain"
}

function install_zsh() {
  if [ -z "$(command -v zsh | sudo tee -a /etc/shells)" ] || [ ! -d ~/.oh-my-zsh ]; then
    install_packages "zsh"

    # unattended -> not trying to change the default shell, and it also won't run zsh when the installation has finished.
    bash -c $(curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh") "" --unattended

    # remove not used stuff
    local exclude_ext pluginDir pluginDirName

    exclude_ext=("git")

    rm -rf "$HOME"/.oh-my-zsh/themes/*
    for pluginDir in ~/.oh-my-zsh/plugins/*; do
      pluginDirName="$(basename "${pluginDir}")"
      # NOTE: invert by removing !
      if [ -d "${pluginDir}" ] && [[ ! "${exclude_ext[*]}" =~ ${pluginDirName} ]]; then
        rm -rf "${pluginDir}"
      fi
    done
    printf "\n# custom injected\n/themes\n/plugins\n" >> "$HOME"/.oh-my-zsh/.gitignore

    # install theme 
    git clone -q --depth=1 https://gitee.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/themes/powerlevel10k || die "Unable to clone p10k"
    # install plugins
    git clone -q https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions || die "Unable to clone zsh-autosuggestions"
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting || die "Unable to clone zsh-syntax-highlighting"
    git clone -q https://github.com/paulirish/git-open.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/git-open || die "Unable to clone git-open"
    # replace string to avoid console output
    # shellcheck disable=SC2016
    sed -i 's/${BROWSER:-$open} "$openurl"/${BROWSER:-$open} "$openurl" > \/dev\/null 2>\&1/' "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/git-open/git-open
  else
    printf "Skipping: zsh already installed.\n"
  fi

  symlink_zsh_config
}

function install_essentials() {
  sudo apt-get update && sudo apt-get -y dist-upgrade
  install_base_packages
  install_timezone
  install_git
  install_fonts
  install_language
  install_ssh
  install_zsh
}

check_preconditions
install_essentials
