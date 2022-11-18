#!/bin/bash
set -euxo pipefail

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

. "${dir}"/_config.sh

sudo -v

# test things here
