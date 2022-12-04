# clean up current ssh agent (delete ssh- directory in /tmp)
if [ -n "$SSH_AGENT_PID" ]; then
  agents=$(ps -p "${SSH_AGENT_PID}" >/dev/null 2>&1 | grep ssh-agent)
  [ -n "${agents}" ] && kill "${SSH_AGENT_PID}"
fi

# when leaving the console clear the screen to increase privacy
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi