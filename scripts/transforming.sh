#!/usr/bin/env bash
#
# Transforming -- use the .xml files received by scraping.sh to generate a csv file with the interesting info about the stations
#
# Author: Bauke Blomme

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide some errors in pipes

#
# Variables
#

PARENT_DIR=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"/..
    pwd -P
)
TEMPFILE=tempfile.txt
TRANSFORMED_DATA_DIR=transformed_data
TRANSFORMED_DATA_FILE=transformed.csv
TRANSFORMED="$PARENT_DIR/$TRANSFORMED_DATA_DIR/$TRANSFORMED_DATA_FILE"

# can't use source scraping.sh here because that'll execute all of the code again. instead i'm using grep to get the hardcoded dirname
DIRNAME=$(grep 'DIRNAME=' "$PARENT_DIR/scripts/scraping.sh" | sed 's/^.*DIRNAME="\([^"]\+\)".*$/\1/')
SCRIPT_NAME=$(basename "$0")

#
# Functions
#

set_up_files() {
    # add transformed data directory of it doesn't exist yet
    if [ ! -d "$PARENT_DIR/$TRANSFORMED_DATA_DIR/" ]; then
        mkdir "$PARENT_DIR/$TRANSFORMED_DATA_DIR/"
    fi

    # empty transofrmed file
    if [ -f "$TRANSFORMED" ]; then
        echo "" >"$TRANSFORMED"
    fi

    # create temporary file to edit lines in
    touch "$TEMPFILE"
}

read_all_scrapes() {
    # will take the oldest file first so most recent lines are at the bottom
    for bestand in "$PARENT_DIR/$DIRNAME/"*; do
        # check if file has been loaded enough to be a usable format
        inhoud="$(cat "$bestand")"
        if [[ $inhoud == *"</liveboard>" ]]; then
            echo "$inhoud" >>"$TEMPFILE"
        fi
    done

    # if tempfile is empty, there are no scrape files. remove tempfile and end script
    if [ ! -s "$TEMPFILE" ]; then
        rm "$TEMPFILE"
        exit 0
    fi
}

transform_to_csv() {
    # every liveboard on a newline
    sed -i 's/<\/liveboard>/\n/g' "$TEMPFILE"
    sed -i 's/<liveboard[^<>]\+>//g' "$TEMPFILE"

    # format depID, depLocX, depLocY and depName
    sed -i 's/^<station URI="[^"]\+" id="\([^"]\+\)" locationX="\([^"]\+\)" locationY="\([^"]\+\)" standardname="\([^"]\+\)">[^<>]\+<\/station>/\1;\2;\3;\4/g' "$TEMPFILE"

    # format delay, canceled, left, isExtra, destID, destLocX, destLocY and destName
    sed -i 's/<departure id="[^"]\+" delay="\([^"]\+\)" canceled="\([^"]\+\)" left="\([^"]\+\)" isExtra="\([^"]\+\)"><station URI="[^"]\+" id="\([^"]\+\)" locationX="\([^"]\+\)" locationY="\([^"]\+\)" standardname="\([^"]\+\)">[^<>]\+<\/station>/\n\1;\2;\3;\4;\5;\6;\7;\8/g' "$TEMPFILE"

    # format depTime, vehicleID, platformNormal, platform and occupancy
    sed -i 's/<time formatted[^<>]\+>\([^<>]\+\)<[^<>]\+><vehicle[^<>]\+>\([^<>]\+\)<\/vehicle><platform normal="\([^"]\+\)">\([^<>]\+\)<\/platform><occupancy[^<>]\+>\([^<>]\+\)<\/occupancy>.*$/;\1;\2;\3;\4;\5/g' "$TEMPFILE"

    # removing "unknown" and "?" for unknown values and just put an empty string
    sed -i 's/unknown\|?//g' "$TEMPFILE"

    # replacing occupancy strings with values that can be used in calculations
    sed -i 's/;low$/;-1/g;s/;high$/;1/g;s/;medium$/;0/g' "$TEMPFILE"

    # formatting stations with zero departures
    sed -i 's/<departures number="0"><\/departures>/\n;;;;;;;;;;;;;/g' "$TEMPFILE"

    # remove end of departures section
    sed -i 's/<departures number="[0-9]\+">//g;s///g' "$TEMPFILE"

    # remove empty lines
    sed -i '/^\s*$/d' "$TEMPFILE"

    # add a header to transformed data file
    echo "depID;depLocX;depLocY;depName;delay;canceled;left;isExtra;destID;destLocX;destLocY;destName;depTime;vehicleID;platformNormal;platform;occupancy" >"$TRANSFORMED"

    # merge departures with their station, then add these to the final file
    stationInfo=""
    while read -r line; do
        if [[ "$line" == "BE"* ]]; then
            stationInfo="$line"
        else
            echo "$stationInfo;$line" >>"$TRANSFORMED"
        fi
    done <"$TEMPFILE"
}

# keep_latest_info_only() {
#     # liveboard info of the same train can be received, as to no get any duplicate info
#     # and only keep the most updated data (as to account for changing delay, occupancy, etc.),
#     # remove older lines about the same train

#     # a train can be uniquely identified using the departure station, the arrival station and
#     # the departure time (suppose not more than one train departs at exactly the same time
#     # from one station to another)

#     # sort the temporary file on these unique identifiers, then per row, check if they are equal
#     # of these identifiers are equal, only keep the last one
#     sort -t ';' -k1 -k9 -k13 "$TRANSFORMED" >"$TEMPFILE"

#     # add a header to transformed data file
#     echo "depID;depLocX;depLocY;depName;delay;canceled;left;isExtra;destID;destLocX;destLocY;destName;depTime;vehicleID;platformNormal;platform;occupancy" >"$TRANSFORMED"

#     lastline=""
#     while read -r line; do
#         thisline="$(echo "$line" | sed 's/\([^;]*;\)\([^;]*;\)\{7\}\([^;]*\);\([^;]*;\)\{3\}\([^;]*;\)[^;]*;[^;]*;[^;]*;[^;]*/\1\3\5/')"
#         if [[ "$lastline" != "$thisline" ]]; then
#             echo "$line" >>"$TRANSFORMED"
#         fi
#         lastline="$thisline"
#     done <"$TEMPFILE"

#     rm "$TEMPFILE"
# }

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

set_up_files

read_all_scrapes

transform_to_csv

# keep_latest_info_only

rm "$TEMPFILE"

exit 0
