#!/usr/bin/env bash

# dont use: set -euo pipefail

if ! grep -qEi "(microsoft|WSL)" /proc/version; then
    exit 0;
fi

WIN_USER_HOME=$(echo "$PATH" | grep -oP '/mnt/c/Users/[^/:]+' | head -n 1)
# Path to the npiperelay executable on the Windows host (adjust as needed)
NPIPERELAY_PATH="${WIN_USER_HOME}/npiperelay.exe" 

# Path for the Unix socket in WSL that SSH clients will use
export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"

# The Windows named pipe used by the OpenSSH Agent
WINDOWS_PIPE="//./pipe/openssh-ssh-agent"

# 1. Check if the socket file exists AND a process is listening on it
if ! ss -a | grep -q "$SSH_AUTH_SOCK"; then
    # 2. If no process is listening, remove any stale socket file
    rm -f "$SSH_AUTH_SOCK"

    # 3. Start the socat/npiperelay bridge in the background
    # setsid makes the process independent of the terminal session
    # socat listens on the Unix socket and executes npiperelay to talk to the Windows named pipe
    ( setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"$NPIPERELAY_PATH -ei -s $WINDOWS_PIPE",nofork & ) >/dev/null 2>&1
fi