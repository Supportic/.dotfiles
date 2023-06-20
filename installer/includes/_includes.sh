#!/bin/bash
set -euo pipefail

currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

. "${currentDir}"/includes/helpers/_parseArguments.sh
. "${currentDir}"/includes/helpers/_const.sh
. "${currentDir}"/includes/helpers/_utils.sh
