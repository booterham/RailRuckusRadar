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

# TODO: nog invullen

usage() { 
cat << _EOF_
Usage: ${0} 

_EOF_
}



#
# Variables
#
DIRNAME="scrapes"
STARTTIME=$(date '+%Y%m%d-')

echo "$STARTTIME"

#
# Command line parsing - niet nodig hier
#

#
# Script proper
#

# bij eerste keer zal de directory voor scrapes nog niet zijn aangemaakt
# dus we maken deze aan 
# en scrapen stations
if [ ! -d ../"$DIRNAME" ]; then
    mkdir ../$DIRNAME;
    mkdir ../stations;
    curl -sS https://api.irail.be/stations/?format=json -o ../stations/stations.json;
    chmod 400 ../stations/stations.json;
fi



