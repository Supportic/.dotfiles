# executes before shell init

# windows WSL: ssh agent does not persist after session, recreate it
# verify: ssh-add -l
# debug: killall ssh-agent
if [ -z "${SSH_AUTH_SOCK}" ]; then
  # Check for a currently running instance of the agent
  RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
  if [ "${RUNNING_AGENT}" = "0" ]; then
      # Launch a new instance of the agent
      ssh-agent -s &> "${HOME}"/.ssh/ssh-agent
  fi
  eval "$(cat ${HOME}/.ssh/ssh-agent)" > /dev/null 2>&1
  # ssh-agent also should automatically add keys inside ~/.ssh
  grep -slR "PRIVATE" ~/.ssh/ | xargs -t ssh-add > /dev/null 2>&1
fi

# mainly for MAC, verify: keychain -L
if [ -x "$(command -v keychain)" ]; then
  grep -slR "PRIVATE" ~/.ssh/ | xargs keychain --eval --agents ssh > /dev/null 2>&1
fi