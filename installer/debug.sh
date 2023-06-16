#!/bin/bash
set -euo pipefail
# set -x

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

. "${currentDir}"/_config.sh

sudo -v

# test things here

function install_git() {
  sudo add-apt-repository -y ppa:git-core/ppa
  install_packages "git"
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

sudo apt-get update && sudo apt-get -y dist-upgrade
sudo DEBIAN_FRONTEND="noninteractive" TZ="${TZ}" apt-get -y install \
    software-properties-common \
    curl
install_git
install_zsh