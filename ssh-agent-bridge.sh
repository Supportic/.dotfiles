#!/usr/bin/env bash

# dont use: set -euo pipefail

if ! grep -qEi "(microsoft|WSL)" /proc/version; then
    exit 0;
fi

# path for the Unix socket in WSL that SSH clients will use
export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"

# The Windows named pipe used by the OpenSSH Agent
WINDOWS_PIPE="//./pipe/openssh-ssh-agent"
WIN_USER_HOME=$(echo "$PATH" | grep -oP '/mnt/c/Users/[^/:]+' | head -n 1 | tr -d '\r\n ')

# abort if the path is empty (e.g., during early subshell initialization)
if [ -z "$WIN_USER_HOME" ]; then
    return 0
fi

# path to the npiperelay executable on the Windows host (adjust as needed)
NPIPERELAY_PATH="${WIN_USER_HOME}/npiperelay.exe" 

# check if the socket file exists AND a process is listening on it
sshpid=$(ss -ap | grep "$SSH_AUTH_SOCK")
if [ "$1" = "-k" ] || [ "$1" = "-r" ]; then
    sshpid=${sshpid//*pid=/}
    sshpid=${sshpid%%,*}
    if [ -n "${sshpid}" ]; then
        kill "${sshpid}"
    else
        echo "socat not found or PID not found"
    fi
    if [ "$1" = "-k" ]; then
        exit
    fi
    unset sshpid
fi

if [ -z "${sshpid}" ]; then
    # if no process is listening, remove any stale socket file
    rm -f "$SSH_AUTH_SOCK"

    # start the socat/npiperelay bridge in the background
    # setsid makes the process independent of the terminal session
    # socat listens on the Unix socket and executes npiperelay to talk to the Windows named pipe
    ( setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"$NPIPERELAY_PATH -ei -s $WINDOWS_PIPE",nofork & ) >/dev/null 2>&1
fi