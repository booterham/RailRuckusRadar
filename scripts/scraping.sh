#!/usr/bin/env bash
#
# Script name -- purpose
#
# Author: Bauke Blomme

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide some errors in pipes
set +e          # disable immediate exit on errors

#
# Functions
#

configure_stations () {
    touch "$PARENT_DIR"/stations/stations.json;
    echo "$(date '+%Y/%m/%d-%H:%M:%S') --- curl stations" >> "$PARENT_DIR"/events.log;
    curl -sS https://api.irail.be/stations/?format=json -o "$PARENT_DIR"/stations/stations.json 2>> "$PARENT_DIR"/events.log;
    chmod 400 "$PARENT_DIR"/stations/stations.json; # readonly because these can't be changed
    # check if curl returned station_ids
    if ! mapfile -t station_ids < <(grep -Eo '"id":"[^"]+"' "$PARENT_DIR"/stations/stations.json | sed 's/"id":"\([^"]\+\)"/\1/'); then
        # curl didn't return station ids. log this and remove station file and directory
        echo "$(date '+%Y/%m/%d-%H:%M:%S')" "---" "Failed getting stations. Check your internet connection or if the URL has changed." >> "$PARENT_DIR"/events.log;
        rm -rf "$PARENT_DIR"/stations;
        exit 1;
    fi
}


#
# Variables
#

DIRNAME="scrapes"
export DIRNAME
# using the name of the parent directory so that this script can be executed from any directory (this makes sure that files and directories
# arent created in the wrong places)
PARENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")"/.. ; pwd -P );
STARTTIME=$(date '+%Y%m%d-%H%M%S');


#
# Script
#

### when called the first time, we get a list of all the stations and create a directory for the scraped data to end up in
if [ ! -d "$PARENT_DIR"/stations ]; then
    echo "no stations dir"
    mkdir "$PARENT_DIR"/stations;
fi

if [ ! -f "$PARENT_DIR"/stations/stations.json ]; then
echo "no stations file"
    configure_stations;
fi

### if a directory for scrapes doesn't exist yet, create it
if [ ! -d "$PARENT_DIR"/"$DIRNAME" ]; then
    mkdir "$PARENT_DIR"/"$DIRNAME";
fi

### loop over all the stations and get the current timetable
# first, get all the station ids from the station.json file
mapfile -t station_ids < <(grep -Eo '"id":"[^"]+"' "$PARENT_DIR"/stations/stations.json | sed 's/"id":"\([^"]\+\)"/\1/');



SCRAPES="$PARENT_DIR"/"$DIRNAME"/data-"$STARTTIME".xml;
touch "$SCRAPES";

for station_id in "${station_ids[@]}"
do
    echo "$(date '+%Y/%m/%d-%H:%M:%S')" "---" "Getting liveboard for ""$station_id" >> "$PARENT_DIR"/events.log;
    curl -s -S https://api.irail.be/liveboard/?id="$station_id" >> "$SCRAPES" 2>> "$PARENT_DIR"/events.log;
done

chmod 400 "$SCRAPES"; # readonly because the data shouldnt be changed