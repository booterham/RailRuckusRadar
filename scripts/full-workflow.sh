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
# Functions
#

#
# Variables
#
PARENT_DIR=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"/..
    pwd -P
)

#
# Script
#

# scrape and wait for it to finish
while [ true ]; do
    /bin/bash "$PARENT_DIR/scripts/scraping.sh"
    /bin/bash "$PARENT_DIR/scripts/transforming.sh"
    # python3 "$PARENT_DIR/scripts/analysis.py"
    # /bin/bash "$PARENT_DIR/scripts/rapport.sh"
done
