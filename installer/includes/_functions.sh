#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

. "${currentDir}"/includes/_includes.sh

function symlink_git_config() {
  ! command_exists "git" && failure "Please install git in order to sync git configs." && return;

  current_username=""
  current_email=""

  if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
    local current_username current_email
    # hier weiter machen, es stoppt
    current_username=$(git config --global --get user.name || echo "")
    current_email=$(git config --global --get user.email || echo "")
  fi

  # override
  cp -pu "${TEMPLATE_DIR}"/git-config "${DOTFILES_DIR}"/.gitconfig || die "Unable to copy file: ${TEMPLATE_DIR}/git-config -> ${DOTFILES_DIR}/.gitconfig"
  log "Recreated gitconfig from template."

  # config 
  ln -sfn "${DOTFILES_DIR}"/.gitconfig "${HOME}"/.gitconfig >/dev/null 2>&1
  # ignore 
  ln -sfn "${TEMPLATE_DIR}"/gitignore "${HOME}"/.gitignore >/dev/null 2>&1

  if [ -n "${current_username}" ] && [ -n "${current_email}" ]; then
    git config --global user.name "${current_username}"
    git config --global user.email "${current_email}"
    log "Reused previous git configs."
  fi

  success "Symlinked git configs into ${HOME} directory."
}

function symlink_zsh_config() {
  ! command_exists "zsh" && failure "Please install zsh in order to sync zsh configs." && return;

  ln -sfn "${DOTFILES_DIR}"/aliases.zsh "${HOME}"/.oh-my-zsh/custom/aliases.zsh
  ln -sfn "${DOTFILES_DIR}"/functions.zsh "${HOME}"/.oh-my-zsh/custom/functions.zsh
  ln -sfn "${DOTFILES_DIR}"/.zshenv "${HOME}"/.zshenv
  ln -sfn "${DOTFILES_DIR}"/.zshrc "${HOME}"/.zshrc
  ln -sfn "${DOTFILES_DIR}"/.zlogout "${HOME}"/.zlogout
  ln -sfn "${DOTFILES_DIR}"/.zprofile "${HOME}"/.zprofile
  ln -sfn "${DOTFILES_DIR}"/.p10k.zsh "${HOME}"/.p10k.zsh
  ln -sfn "${DOTFILES_DIR}"/.p10k-intellij.zsh "${HOME}"/.p10k-intellij.zsh

  success "Symlinked zsh configs into ${HOME} directory."
}

function symlink_ssh_config() {
  ! package_exists "openssh-client" && failure "Please install ssh in order to sync ssh config." && return; 

  if [ ! -f "${DOTFILES_DIR}/.sshconfig" ]; then
    cp -pu ${TEMPLATE_DIR}/ssh-config "${DOTFILES_DIR}/.sshconfig" || die "Unable to copy file: ${TEMPLATE_DIR}/ssh-config -> ${DOTFILES_DIR}/.sshconfig"
  fi
  
  # doesn't create dir if exists
  mkdir -p "${HOME}"/.ssh && ln -sfn "${DOTFILES_DIR}/.sshconfig" "$_"/config
}

function symlink_scripts() {
  [ ! -d "${LOCAL_BIN_DIR}" ] && mkdir -p "${LOCAL_BIN_DIR}" && log "Created ${LOCAL_BIN_DIR} directory."
  [ ! -d "${LOCAL_SCRIPTS_DIR}" ] && mkdir -p "${LOCAL_SCRIPTS_DIR}" && log "Created ${LOCAL_SCRIPTS_DIR} directory."

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

  success "Symlinked user scripts into ${LOCAL_SCRIPTS_DIR} directory."
}

function configure_git() {

  if isFalse "${nointeractive}"; then
    ! command_exists "git" && failure "Please install git in order to setup git configurations." && return;

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