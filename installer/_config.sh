#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

. "${currentDir}"/includes/_parseArguments.sh "$@"
. "${currentDir}"/includes/_const.sh
. "${currentDir}"/includes/_utils.sh

function symlink_git_config() {
  if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
    local current_username current_email
    # hier weiter machen, es stoppt
    current_username=$(git config --global --get user.name || echo "")
    current_email=$(git config --global --get user.email || echo "")

    # override
    sudo cp -pu "${TEMPLATE_DIR}"/git-config "${DOTFILES_DIR}"/.gitconfig || die "Unable to copy file: ${TEMPLATE_DIR}/git-config -> ${DOTFILES_DIR}/.gitconfig"

    if [ -n "${current_username}" ] && [ -n "${current_email}" ]; then
      git config --global user.name "${current_username}"
      git config --global user.email "${current_email}"
    fi
  else
    sudo cp -pu "${TEMPLATE_DIR}/git-config" "${DOTFILES_DIR}"/.gitconfig || die "Unable to copy file: ${TEMPLATE_DIR}/git-config -> ${DOTFILES_DIR}/.gitconfig"
  fi

  # config 
  ln -sfn "${DOTFILES_DIR}"/.gitconfig ~/.gitconfig >/dev/null 2>&1
  # ignore 
  ln -sfn "${TEMPLATE_DIR}"/gitignore ~/.gitignore >/dev/null 2>&1
}

function symlink_zsh_config() {
  # change default shell
  sudo chsh -s "$(which zsh)" "$(whoami)"

  ln -sfn "${DOTFILES_DIR}"/aliases.zsh ~/.oh-my-zsh/custom/aliases.zsh
  ln -sfn "${DOTFILES_DIR}"/functions.zsh ~/.oh-my-zsh/custom/functions.zsh
  ln -sfn "${DOTFILES_DIR}"/.zshenv ~/.zshenv
  ln -sfn "${DOTFILES_DIR}"/.zshrc ~/.zshrc
  ln -sfn "${DOTFILES_DIR}"/.zlogout ~/.zlogout
  ln -sfn "${DOTFILES_DIR}"/.zprofile ~/.zprofile
  ln -sfn "${DOTFILES_DIR}"/.p10k.zsh ~/.p10k.zsh
  ln -sfn "${DOTFILES_DIR}"/.p10k-intellij.zsh ~/.p10k-intellij.zsh
}

function symlink_ssh_config() {
  if [ ! -f "${DOTFILES_DIR}/.sshconfig" ]; then
    sudo cp -pu ${TEMPLATE_DIR}/ssh-config "${DOTFILES_DIR}/.sshconfig" || die "Unable to copy file: ${TEMPLATE_DIR}/ssh-config -> ${DOTFILES_DIR}/.sshconfig"
  fi
  
  # doesn't create dir if exists
  mkdir -p ~/.ssh && ln -sfn "${DOTFILES_DIR}/.sshconfig" "$_"/config
}

function symlink_scripts() {
  [ ! -d "${LOCAL_BIN_DIR}" ] && mkdir -p "${LOCAL_BIN_DIR}"
  [ ! -d "${LOCAL_SCRIPTS_DIR}" ] && mkdir -p "${LOCAL_SCRIPTS_DIR}"

  rm -f "${LOCAL_SCRIPTS_DIR}"/*

  local script
  # for script in ${DOTFILES_DIR}/bin/* ${DOTFILES_DIR}/bin/**/*; do
  for script in $(find "${DOTFILES_DIR}"/bin -name "*.sh"); do
    if [ -f $script ]; then
      chmod u+x $script
      filename=$(basename ${script%.*})
      ln -sfn $script "${LOCAL_SCRIPTS_DIR}"/$filename
    fi
  done
}

function configure_git() {

  if isFalse "${nointeractive}"; then

    if [ -z "$(git config --global --get user.name)" ] ||
       [ -z "$(git config --global --get user.email)" ]
    then
      print_info_banner "We are almost done. Let's setup some user configurations...";
    fi

    if [ -z "$(git config --global --get user.name)" ]; then
      read -ep $'Git username: ' git_user
      git config --global user.name "${git_user}"
    fi
    if [ -z "$(git config --global --get user.email)" ]; then
      read -ep $'Git email: ' git_email
      git config --global user.email "${git_email}"
    fi
  fi
}