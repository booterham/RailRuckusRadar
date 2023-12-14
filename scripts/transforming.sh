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
DIRNAME=$(grep 'DIRNAME=' "$PARENT_DIR"/scripts/scraping.sh | sed 's/^.*DIRNAME="\([^"]\+\)".*$/\1/')

#
# Script proper
#

### check if there's already a directory that contains transformed data
### if this is the case, delete everything and start over
# todo
if [ ! -d "$PARENT_DIR"/transformed_data/ ]; then
    mkdir "$PARENT_DIR"/transformed_data/;
fi

if [ -f "$PARENT_DIR"/transformed_data/transformed.csv ]; then
    rm "$PARENT_DIR"/transformed_data/transformed.csv;
fi

touch "$PARENT_DIR"/transformed_data/transformed.csv;
touch tempfile.txt
TEMPFILE=tempfile.txt
TRANSFORMED="$PARENT_DIR"/transformed_data/transformed.csv


for bestand in "$PARENT_DIR"/"$DIRNAME"/*
do
    # als het bestand nog niet volledig ingeladen is op dit moment, door scraping.sh, sla het over
    inhoud="$(cat "$bestand")"
    if [[ $inhoud == *"</liveboard>" ]];then
        echo "$inhoud" >> "$TEMPFILE"
    fi
done

# remove possible errors
sed -i 's/<error code="[0-9]\+">[^<>]\+<[^<>]\+>//g' "$TEMPFILE"

# every liveboard on a newline
sed -i 's/\(<\/liveboard>\)/\1\n/g' "$TEMPFILE"

# ignore stations that have no departures
grep -E '^.+departures number="[^0][0-9]*".+$' "$TEMPFILE" > more_than_zero.csv
mv more_than_zero.csv "$TEMPFILE"

# per liveboard, only use timestamp, station id and station name
# then per departure, only use departureId; delay; canceled; left; isExtra; destId; destName; vehicleName, platform
# every liveboard and every departuse gets its own line
sed -i 's/<liveboard version="[0-9\.]\+" timestamp="\([0-9]\+\)"><station locationX="[^"]\+" locationY="[^"]\+" id="\([^"]\+\)" URI="[^"]\+" standardname="\([^"]\+\)">[^>]\+><[^>]\+>/\1;\2;\3/g;s/<departure id="\([0-9]\+\)" /\n;\1;/g;s/delay="\([^"]\+\)" canceled="\([^"]\+\)" left="\([^"]\+\)" isExtra="\([^"]\+\)"><station locationX="[^"]\+" locationY="[^"]\+" id="\([^"]\+\)" URI="[^"]\+" standardname="\([^"]\+\)">[^>]\+><[^>]\+>\([0-9]\+\)<\/time><[^>]\+>\([^<]\+\)[^>]\+><[^"]\+"\([^"]\+\)">[^>]\+><[^<>]\+>[^<>]\+<[^<>]\+><[^<>]\+>/\1;\2;\3;\4;\5;\6;\7;\8;\9/g;s/<\/departures><\/liveboard>//g' "$TEMPFILE"

# merge departures with their station, then add these to the final file
echo "timestamp;stationId;stationName;departureId;delay;canceled;left;isExtra;destId;destName;departureTime;vehicleName;platform" >> "$TRANSFORMED"
station_info=""
while read -r line; do
    if [[ $line == ";"* ]];then
        departureInfo="$station_info$line";
        echo "$departureInfo" >> "$TRANSFORMED"
    else
        station_info="$line";
    fi
done < "$TEMPFILE"
rm "$TEMPFILE"

# remove duplicate lines
mv "$TRANSFORMED" "$TEMPFILE"
uniq "$TEMPFILE" "$TRANSFORMED"


rm "$TEMPFILE"