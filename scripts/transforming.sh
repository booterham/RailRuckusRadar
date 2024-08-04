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
    # check if file has been loaded enough to be a usable format
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

# departure stations
### station URI, id, locationX, locationY & standardname
sed -i 's/^<station URI="[^"]\+" id="\([^"]\+\)" locationX="\([^"]\+\)" locationY="\([^"]\+\)" standardname="\([^"]\+\)">[^<>]\+<\/station>/\1;\2;\3;\4/g' "$TEMPFILE"

# destination stations
### delay, canceled, left, isExtra, destID, locationX, locationY, destname
sed -i 's/<departure id="[^"]\+" delay="\([^"]\+\)" canceled="\([^"]\+\)" left="\([^"]\+\)" isExtra="\([^"]\+\)"><station URI="[^"]\+" id="\([^"]\+\)" locationX="\([^"]\+\)" locationY="\([^"]\+\)" standardname="\([^"]\+\)">[^<>]\+<\/station>/\n\1;\2;\3;\4;\5;\6;\7;\8/g' "$TEMPFILE"

# formatting departure time, vehiclename, platform normal, platform and occupancy
sed -i 's/<time formatted[^<>]\+>\([^<>]\+\)<[^<>]\+><vehicle[^<>]\+>\([^<>]\+\)<\/vehicle><platform normal="\([^"]\+\)">\([^<>]\+\)<\/platform><occupancy[^<>]\+>\([^<>]\+\)<\/occupancy>.*$/;\1;\2;\3;\4;\5/g' "$TEMPFILE"

# removing the work "unknown" and "?" for unknown values and just put an empty string
sed -i 's/unknown\|?//g' "$TEMPFILE"

# formatting stations with zero departures
sed -i 's/<departures number="0"><\/departures>/\nnoDepartures/g' "$TEMPFILE"

# remove departure numbers and end of departures section
sed -i 's/<departures number="[0-9]\+">//g;s///g' "$TEMPFILE"

# remove empty lines
sed -i '/^\s*$/d' "$TEMPFILE"

# merge departures with their station, then add these to the final file
stationInfo=""
while read -r line; do
    if [[ "$line" == "BE"* ]]; then
        stationInfo="$line"
    else
        if [[ "$line" == "noDepartures" ]]; then
            echo "$stationInfo;;;;;;;;;;;;;" >>"$TRANSFORMED"
        else
            echo "$stationInfo;$line" >>"$TRANSFORMED"
        fi
    fi
done <"$TEMPFILE"

# for liveboard info about the same train, only keep the last one since this one will have
# most up-to-date information about delays etc.
### put the delay column as

# what info can change for specific train
### delayed, canceled, left, platformnormal, platform, occupancy
### col: 5, 6, 7, 15, 16, 17, so we need to leave these out when we sort

# we run through the file and keep the last line, of the regex of the unique
# identifiers of the last line (depstation, arrstation and vehID), matches
# the current line, make the current line the last line. if it doesnt match, the last line has
#the most up to date info and it can be added to transformed data file

sort -t ';' -k1 -k9 -k13 "$TRANSFORMED" >"$TEMPFILE"

# add a header to transformed data file
echo "depID;depLocX;depLocY;depName;delay;canceled;left;isExtra;destID;destLocX;destLocY;destName;depTime;vehicleID;platformNormal;platform;occupancy" >"$TRANSFORMED"

lastline=""
while read -r line; do
    thisline="$(echo "$line" | sed 's/\([^;]*;\)\([^;]*;\)\{7\}\([^;]*\);\([^;]*;\)\{3\}\([^;]*;\)[^;]*;[^;]*;[^;]*;[^;]*/\1\3\5/')"
    if [[ "$lastline" != "$thisline" ]]; then
        echo "$line" >>"$TRANSFORMED"
    fi
    lastline="$thisline"
done <"$TEMPFILE"

rm "$TEMPFILE"

exit 0

# rm "$TEMPFILE"
