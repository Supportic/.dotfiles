#!/bin/bash
set -euo pipefail

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

. "${dir}"/includes/_parseArguments.sh "$@"
. "${dir}"/includes/_const.sh
. "${dir}"/includes/_utils.sh

function setup_git() {
  if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
    local current_username="$(git config --global --get user.name)"
    local current_email="$(git config --global --get user.email)"
    # override
    sudo cp -pu ${TEMPLATE_DIR}/git-config "${DOTFILES_DIR}/.gitconfig" || die "Unable to copy file: ${TEMPLATE_DIR}/git-config -> ${DOTFILES_DIR}/.gitconfig"
    git config --global user.name "${current_username}"
    git config --global user.email "${current_email}"
  else
    sudo cp -pu "${TEMPLATE_DIR}/git-config" "${DOTFILES_DIR}/.gitconfig" || die "Unable to copy file: ${TEMPLATE_DIR}/git-config -> ${DOTFILES_DIR}/.gitconfig"
  fi
  
  ln -sfn "${DOTFILES_DIR}/.gitconfig" ~/.gitconfig 2> /dev/null
}

function setup_zsh() {
  # change default shell
  sudo chsh -s "$(which zsh)" "$(whoami)"

  ln -sfn "${DOTFILES_DIR}/aliases.zsh" ~/.oh-my-zsh/custom/aliases.zsh
  ln -sfn "${DOTFILES_DIR}/functions.zsh" ~/.oh-my-zsh/custom/functions.zsh
  ln -sfn "${DOTFILES_DIR}/.zshenv" ~/.zshenv
  ln -sfn "${DOTFILES_DIR}/.zshrc" ~/.zshrc
  ln -sfn "${DOTFILES_DIR}/.zlogout" ~/.zlogout
  ln -sfn "${DOTFILES_DIR}/.p10k.zsh" ~/.p10k.zsh
}

function setup_ssh() {
  if [ ! -f "${DOTFILES_DIR}/.sshconfig" ]; then
    sudo cp -pu ${TEMPLATE_DIR}/ssh-config "${DOTFILES_DIR}/.sshconfig" || die "Unable to copy file: ${TEMPLATE_DIR}/ssh-config -> ${DOTFILES_DIR}/.sshconfig"
  fi
  
  # doesn't create dir if exists
  mkdir -p ~/.ssh && ln -sfn "${DOTFILES_DIR}/.sshconfig" "$_"/config
}

function setup_scripts() {
  [ ! -d ~/bin ] && mkdir -p ~/bin
  local script=
  for script in ${DOTFILES_DIR}/scripts/* ${DOTFILES_DIR}/scripts/**/*; do
    if [ -f $script ]; then
      chmod u+x $script
      filename=$(basename $script)
      ln -sfn $script ~/bin/$filename
    fi
  done
}

function configure_settings() {

  if ! isTrue "${nointeractive:-false}"; then

    print_info "We are almost done. Let's setup some user configurations...";
    if [ -z "$(git config --global --get user.name)" ]; then
      read -ep $'Git username: ' git_user
      git config --global user.name "${git_user}"
    fi
    if [ -z "$(git config --global --get user.email)" ]; then
      read -ep $'Git email: ' git_email
      git config --global user.email "${git_email}"
    fi
  fi

  zsh -c "source ~/.zshrc"
}