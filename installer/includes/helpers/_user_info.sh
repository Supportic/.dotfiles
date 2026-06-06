#!/bin/bash
set -euo pipefail

# User environment detection and helper functions
# This script sets up INVOKING_USER, INVOKING_HOME, and related variables
# to ensure proper path handling when running with sudo

function setup_user_environment() {
  local uid
  uid=$(id -u)

  if [ "${uid}" -eq 0 ]; then
    # Running as root
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
      # Sudo from regular user
      export INVOKING_USER="${SUDO_USER}"
      export INVOKING_UID=$(id -u "${SUDO_USER}")
      export INVOKING_GID=$(id -g "${SUDO_USER}")
      export INVOKING_GROUP=$(id -gn "${SUDO_USER}")
      export INVOKING_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
    else
      # Direct root login or root calling itself with sudo
      info "Running directly as root user without sudo. All tools will be installed for the root user. To install for a regular user, please run the script with sudo from that user."
      export INVOKING_USER="root"
      export INVOKING_UID=0
      export INVOKING_GID=0
      export INVOKING_GROUP="root"
      export INVOKING_HOME="/root"
    fi
  else
    # Running as regular user (no sudo)
    export INVOKING_USER="$(whoami)"
    export INVOKING_UID="${uid}"
    export INVOKING_GID=$(id -g)
    export INVOKING_GROUP=$(id -gn)
    export INVOKING_HOME="${HOME}"
  fi

  # Export for use in subshells
  readonly INVOKING_USER
  readonly INVOKING_UID
  readonly INVOKING_GID
  readonly INVOKING_GROUP
  readonly INVOKING_HOME
}

# Run a command as the invoking user when script is running as root
# -u with user ownership
# Usage: sudo_user command arg1 arg2
function sudo_user() {
  if [ "$(id -u)" -eq 0 ]; then
    sudo -u "${INVOKING_USER}" "$@"
  else
    "$@"
  fi
}

# Initialize user environment
setup_user_environment
