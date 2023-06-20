#!/bin/bash
set -euo pipefail

# Convenience functions.
function usage_error () { 
  echo >&2 "$(basename $0):  $1";
  exit 2;
}
function assert_argument () {
   test "$1" != "$EOL" || usage_error "$2 requires an argument"; 
}

# defaults
nointeractive="false"
should_install_essentials="false"
should_install_tools="false"
should_create_symlinks="false"

# One loop, nothing more.
if [ "$#" != 0 ]; then
  EOL=$(printf '\1\3\3\7')
  set -- "$@" "$EOL"
  while [ "$1" != "$EOL" ]; do
    opt="$1"; shift
    case "$opt" in

      # Your options go here. If provided then set value.
      -ni|--nointeractive) nointeractive="true";;
      --sync) should_create_symlinks="true";;
      --essentials) should_install_essentials="true";;
      --tools) should_install_tools="true";;

      # Arguments processing. You may remove any unneeded line after the 1st.
      -|''|[!-]*) set -- "$@" "$opt";;                                          # positional argument, rotate to the end
      --*=*)      set -- "${opt%%=*}" "${opt#*=}" "$@";;                        # convert '--name=arg' to '--name' 'arg'
      -[!-]?*)    set -- $(echo "${opt#-}" | sed 's/\(.\)/ -\1/g') "$@";;       # convert '-abc' to '-a' '-b' '-c'
      --)         while [ "$1" != "$EOL" ]; do set -- "$@" "$1"; shift; done;;  # process remaining arguments as positional
      -*)         usage_error "unknown option: '$opt'";;                        # catch misspelled options
      *)          usage_error "this should NEVER happen ($opt)";;               # sanity test for previous patterns

    esac
  done
  shift  # $EOL
fi