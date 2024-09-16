#!/usr/bin/env bash
#
# Rapport -- Generate a rapport based on the graphs from analysis.py
#
# Author: Bauke Blomme

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide some errors in pipes
set +e          # disable immediate exit on errors

#
# Variables
#
PARENT_DIR=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"/..
    pwd -P
)
SCRIPT_NAME=$(basename "$0")

#
# Functions
#

avoid_duplicate_instances() {
    # Get the current script's PID
    CURRENT_PID=$$

    # Check if the script is already running (excluding the current process)
    if pgrep -f "$SCRIPT_NAME" | grep -v "^$CURRENT_PID$" >/dev/null; then
        exit 0
    fi
}

#
# Script
#

avoid_duplicate_instances

# go to directory of this bash script
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR" || exit

/bin/bash "$PARENT_DIR/scripts/scraping.sh"
/bin/bash "$PARENT_DIR/scripts/transforming.sh"
python3 "$PARENT_DIR/scripts/analysis.py"
/bin/bash "$PARENT_DIR/scripts/rapport.sh"
