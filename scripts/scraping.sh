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

configure_stations () {
    mkdir "$PARENT_DIR"/stations;
    curl -sS https://api.irail.be/stations/?format=json -o "$PARENT_DIR"/stations/stations.json;
    chmod 400 "$PARENT_DIR"/stations/stations.json; # readonly want dit mag niet aangepast worden
}

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
export DIRNAME
# using the name of the parent directory so that this script can be executed from any directory (this makes sure that files and directories
# arent created in the wrong places)
PARENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")"/.. ; pwd -P )
STARTTIME=$(date '+%Y%m%d-%H%M%S')


#
# Script
#

### when called the first time, we get a list of all the stations and create a directory for the scraped data to end up
if [ ! -d "$PARENT_DIR"/"$DIRNAME" ]; then
    mkdir "$PARENT_DIR"/"$DIRNAME";
    configure_stations;
fi

### loop over all the stations and get the current timetable
# first, get all the station ids from the station.json file
mapfile -t station_ids < <(grep -Eo '"id":"[^"]+"' "$PARENT_DIR"/stations/stations.json | sed 's/"id":"\([^"]\+\)"/\1/')

# for f in "${station_ids[@]}"
# do
#   echo "$f"
# done

SCRAPES="$PARENT_DIR"/"$DIRNAME"/data-"$STARTTIME".xml
touch "$SCRAPES"

for station_id in "${station_ids[@]}"
do
    echo "|$station_id|"
    curl -s https://api.irail.be/liveboard/?id="$station_id" >> "$SCRAPES"
done

chmod 400 "$SCRAPES"; # readonly want dit mag niet aangepast worden