#!/usr/bin/env bash
#
# Script name -- purpose
#
# Author: Bauke Blomme

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide some errors in pipes

#
# Functions
#

usage() {
cat << _EOF_
Usage: ${0}

_EOF_
}

#
# Variables
#

PARENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")"/.. ; pwd -P )
# can't use source scraping.sh here because that'll execute all of the code again. instead i'm using grep to get the hardcoded dirname
DIRNAME=$(grep 'DIRNAME=' scraping.sh | sed 's/^.*DIRNAME="\([^"]\+\)".*$/\1/')

#
# Script proper
#

### check if there's already a directory that contains transformed data
### if this is the case, delete everything and start over
# todo

for bestand in "$PARENT_DIR"/"$DIRNAME"/*
do
    echo "$bestand"
done