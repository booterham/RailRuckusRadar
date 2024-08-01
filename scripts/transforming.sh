#!/usr/bin/env bash
#
# Transforming -- use the .xml files received by scraping.sh to generate a csv file with the interesting info about the stations
#
# Author: Bauke Blomme

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide some errors in pipes

#
# Functions
#

usage() {
    cat <<_EOF_
Usage: ${0}

_EOF_
}

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

# can't use source scraping.sh here because that'll execute all of the code again. instead i'm using grep to get the hardcoded dirname
DIRNAME=$(grep 'DIRNAME=' "$PARENT_DIR/scripts/scraping.sh" | sed 's/^.*DIRNAME="\([^"]\+\)".*$/\1/')

#
# Script
#

### check if there's already a directory that contains transformed data
### if this is the case, delete everything and start over
### We do this because starting over takes less time than checking where we left off last time

TRANSFORMED="$PARENT_DIR/$TRANSFORMED_DATA_DIR/$TRANSFORMED_DATA_FILE"

if [ ! -d "$PARENT_DIR/$TRANSFORMED_DATA_DIR/" ]; then
    mkdir "$PARENT_DIR/$TRANSFORMED_DATA_DIR/"
fi

if [ -f "$TRANSFORMED" ]; then
    rm "$TRANSFORMED"
    touch "$TRANSFORMED"
fi

touch "$TEMPFILE"

for bestand in "$PARENT_DIR/$DIRNAME/"*; do
    # check if file is newer than $TRANSFORMED_DATA_FILE, if $TRANSFORMED_DATA_FILE doesnt exist, every file will be newer
    # if [ "$bestand" -nt "$TRANSFORMED" ]; then

    # check if file has been fully loaded
    inhoud="$(cat "$bestand")"
    if [[ $inhoud == *"</liveboard>" ]]; then
        echo "$inhoud" >>"$TEMPFILE"
    fi
    # fi
done

# if tempfile is empty, there are no scrape files. remove tempfile and end script
if [ ! -s "$TEMPFILE" ]; then
    rm "$TEMPFILE"
    exit 0
fi

# every liveboard on a newline
sed -i 's/<\/liveboard>/\n/g' "$TEMPFILE"
sed -i 's/<liveboard[^<>]\+>//g' "$TEMPFILE"

# formatting stations
### station URI, id, locationX, locationY & standardname
sed -i 's/^<station URI="[^"]\+" id="\([^"]\+\)" locationX="\([^"]\+\)" locationY="\([^"]\+\)" standardname="\([^"]\+\)">[^<>]\+<\/station>/\1;\2;\3;\4/g' "$TEMPFILE"

# formatting destination stations
sed -i 's/<departure id="[^"]\+" delay="\([^"]\+\)" canceled="\([^"]\+\)" left="\([^"]\+\)" isExtra="\([^"]\+\)"><station URI="\([^"]\+\)" id="\([^"]\+\)" locationX="\([^"]\+\)" locationY="\([^"]\+\)" standardname="\([^"]\+\)">[^<>]\+<\/station>/\n\1;\2;\3;\4;\5;\6;\7;\8;\9/g' "$TEMPFILE"

# formatting departure time, vehiclename, platform normal, platform and occupancy
sed -i 's/<time formatted[^<>]\+>\([^<>]\+\)<[^<>]\+><vehicle[^<>]\+>\([^<>]\+\)<\/vehicle><platform normal="\([^"]\+\)">\([^<>]\+\)<\/platform><occupancy[^<>]\+>\([^<>]\+\)<\/occupancy>.*$/;\1;\2;\3;\4;\5/g' "$TEMPFILE"

# removing the work "unknown" for unknown values and just put an empty string
sed -i 's/unknown\|?//g' "$TEMPFILE"

# formatting stations with zero departures
sed -i 's/<departures number="0"><\/departures>/\nnoDepartures/g' "$TEMPFILE"

# remove departure numbers and end of departures section
sed -i 's/<departures number="[0-9]\+">//g;s///g' "$TEMPFILE"

# add a header to transformed data file
if [ ! -s "$TRANSFORMED" ]; then
    echo "depID;depLocX;depLocY;depName;delay;canceled;left;isExtra;liveURL;destID;destLocX;destLocY;destName;depTime;vehicleID;platformNormal;platform;occupancy" >>"$TRANSFORMED"
fi

# remove empty lines
sed -i '/^\s*$/d' "$TEMPFILE"

# merge departures with their station, then add these to the final file
stationInfo=""
while read -r line; do
    echo "line$line line"
    if [[ "$line" == "BE"* ]]; then
        stationInfo="$line"
    else
        if [[ "$line" == "noDepartures" ]]; then
            echo "$stationInfo;;;;;;;;;;;;;;" >>"$TRANSFORMED"
        else
            echo "$stationInfo;$line" >>"$TRANSFORMED"
        fi
    fi
done <"$TEMPFILE"
rm "$TEMPFILE"

# # remove duplicate lines
# mv "$TRANSFORMED" "$TEMPFILE"
# uniq "$TEMPFILE" "$TRANSFORMED"

# for liveboard info about the same train, only keep the last one since this one will have most up-to-date information about delays etc.
# todo

# rm "$TEMPFILE"
