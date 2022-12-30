#!/bin/bash
set -euo pipefail

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# shellcheck source=./_config.sh
. "${dir}"/_config.sh

printf "This script will configure your Linux machine and install the following programs: 
- zsh / exa / bat / btop / trash-cli / pigz
- docker / git / ssh
\n"

if isFalse "${nointeractive}"; then
  read -rep $'Do you want to continue? [y/n]: ' canStart
  isFalse "$canStart" && echo "Stopped: script exited." && exit;
  echo "Setting up Linux..."
fi

# set /etc/localtime and /etc/timezone
function install_timezone() {
  sudo ln -sfn /usr/share/zoneinfo/"${TZ}" /etc/localtime
  # writes TZ into /etc/timezone
  sudo dpkg-reconfigure -f noninteractive tzdata 2> /dev/null
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
    locales \
    curl \
    wget \
    zip unzip \
    tree \
    dnsutils \
    net-tools iproute2 \
    lsof
}

function install_git() {
  sudo add-apt-repository -y ppa:git-core/ppa &&\
    sudo apt update &&\
    sudo apt-get -y install git

  setup_git
}

function install_fonts() {
  if [ ! -d "${LOCAL_FONTS_DIR}" ]; then
    echo "Creating fonts directory: ${LOCAL_FONTS_DIR}"
    mkdir -p "${LOCAL_FONTS_DIR}" >/dev/null 2>&1 || die "Unable to create fonts directory: ${LOCAL_FONTS_DIR}"
  fi

  if [ ! -d "${LOCAL_FONTS_DIR}/JetBrains Mono" ]; then
    # Generate temporary filename
    local TEMP_LATEST_INFO
    TEMP_LATEST_INFO=$(mktemp)
    local FONTS_TEMPFILE
    FONTS_TEMPFILE=$(mktemp)
    # Latest fonts release info in JSON
    local LATEST_RELEASE_INFO="https://api.github.com/repos/JetBrains/JetBrainsMono/releases/latest"
    echo "Downloading latest release info: ${LATEST_RELEASE_INFO}"
    download "${LATEST_RELEASE_INFO}" "${TEMP_LATEST_INFO}"
    local TAG_NAME
    TAG_NAME=$(get_item "tag_name" "${TEMP_LATEST_INFO}")
    local BROWSER_URL
    BROWSER_URL=$(get_item "browser_download_url" "${TEMP_LATEST_INFO}")
    echo "Latest fonts version: ${TAG_NAME}"

    echo "Downloading fonts archive: ${BROWSER_URL}"
    download "${BROWSER_URL}" "${FONTS_TEMPFILE}"
    echo "Extracting fonts: ${LOCAL_FONTS_DIR}"
    extract "${FONTS_TEMPFILE}" "${LOCAL_FONTS_DIR}/JetBrains Mono"

    echo "Cleaning up..."
    cleanup "${TEMP_LATEST_INFO}"
    cleanup "${FONTS_TEMPFILE}"
  fi

  echo "Building fonts cache..."
  fc-cache -f || die "Unable to build fonts cache"
  echo "Fonts have been installed"
}

# cat /etc/default/locale
# https://wiki.archlinux.org/title/locale#LANG:_default_locale
function install_language() {
  local de_locale
  local en_locale
  local de
  local en
  local lang_to_install

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

function install_zsh() {
  if [ -z "$(command -v zsh | sudo tee -a /etc/shells])" ] || [ ! -d ~/.oh-my-zsh ]; then
    sudo apt-get -y install zsh
    # unattended -> not trying to change the default shell, and it also won't run zsh when the installation has finished.
    bash -c "$(download https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # remove not used stuff
    local exclude_ext
    local dir
    local dirname

    exclude_ext=(git)

    rm -rf $HOME/.oh-my-zsh/themes/*
    for dir in ~/.oh-my-zsh/plugins/*; do
      dirname="$(basename ${dir})"
      # NOTE: invert by removing !
      if [ -d $dir ] && [[ ! " ${exclude_ext[*]} " =~ " ${dirname} " ]]; then
        rm -rf $dir
      fi
    done
    printf "\n# custom injected\n/themes\n/plugins\n" >> $HOME/.oh-my-zsh/.gitignore

    # install theme 
    git clone -q --depth=1 https://gitee.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/themes/powerlevel10k || die "Unable to clone p10k"
    # install plugins
    git clone -q https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions || die "Unable to clone zsh-autosuggestions"
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting || die "Unable to clone zsh-syntax-highlighting"
  else
    printf "Skipping: zsh already installed.\n"
  fi

  setup_zsh
}

function install_ssh() {
  sudo apt-get -y install openssh-client keychain

  setup_ssh
}

# exa better ls
# bat better cat
# pigz better archive compression than gzip
# trash better rm
function install_utils() {
  if ! command_exists "exa"; then
    local EXA_TEMPFILE
    EXA_TEMPFILE=$(mktemp)
    local EXA_VERSION
    EXA_VERSION=$(download "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    download "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v${EXA_VERSION}.zip" "${EXA_TEMPFILE}"
    # -> /usr/local/bin/exa
    sudo unzip -qo "${EXA_TEMPFILE}" bin/exa -d /usr/local >/dev/null 2>&1
    cleanup "${EXA_TEMPFILE}"
  fi

  if ! command_exists "bat"; then
    local BAT_TEMPDIR
    BAT_TEMPDIR=$(mktemp -d)
    local BAT_VERSION
    BAT_VERSION=$(download "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    
    download "https://github.com/sharkdp/bat/releases/latest/download/bat_${BAT_VERSION}_amd64.deb" "${BAT_TEMPDIR}"/bat_"${BAT_VERSION}"_amd64.deb

    sudo dpkg -i "${BAT_TEMPDIR}"/bat_"${BAT_VERSION}"_amd64.deb >/dev/null 2>&1
    cleanup "${BAT_TEMPDIR}"
  fi

  if ! command_exists "btop"; then
    local BTOP_TEMPFILE
    BTOP_TEMPFILE=$(mktemp)
    local BTOP_TEMPDIR
    BTOP_TEMPDIR=$(mktemp -d)

    download "https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz" "${BTOP_TEMPFILE}"

    sudo tar -jxf "${BTOP_TEMPFILE}" -C "${BTOP_TEMPDIR}"
    sudo cp -pu "${BTOP_TEMPDIR}"/btop/bin/btop /usr/local/bin

    cleanup "${BTOP_TEMPFILE}"
    cleanup "${BTOP_TEMPDIR}"
  fi

  if ! command_exists "pigz"; then
    sudo apt-get -y install pigz 
  fi
  if ! command_exists "trash"; then
    sudo apt-get -y install trash-cli 
  fi
}

# docker && docker-compose v2 and add docker to groups (getent group docker)
function install_docker() {
  if ! command_exists "docker"; then
    sudo mkdir -p /etc/apt/keyrings
    curl https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # curl https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    # sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt-get update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  fi

  # if somehow there is still no group
  [ -z "$(getent group docker)" ] && sudo groupadd docker
  sudo usermod -aG docker "$(whoami)" && newgrp docker
}

function install_main() {
  sudo apt-get update && sudo apt-get -y dist-upgrade
  install_base_packages
  install_timezone
  install_git
  install_fonts
  install_language
  install_zsh
  install_utils
  install_ssh

  # cannot be installed inside of another container
  if isFalse "${nointeractive}" || isFalse "${nodocker}"; then
    install_docker
  fi
}

# make sure we have sudo permission before running the script
sudo -v

# UNIX timestamp concatenated with nanoseconds
start=$(date +%s%N)
install_main
end=$(date +%s%N)
difference="$((end-start))"

setup_scripts
configure_settings

printf "Installation Complete\n"
printf "script took: %s\n" "$(displaytime ${difference})"
