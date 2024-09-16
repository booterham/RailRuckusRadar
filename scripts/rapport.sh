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

function fill_in_placeholder_text() {
    lorem="$(shlorem sentences 20 | sed 's/\./\\./g')"
    sed -i "s/{lorem}/$lorem/g" "$RAPPORT"
}

function fill_in_image() {
    img_title=$(find "$PLOT_DIR" -regex ".*[0-9]_$1\.png" | sed 's/^.*\(top.*\)$/\1/')
    img_title_sed="s/{$2}/$img_title/"
    sed -i "$img_title_sed" "$RAPPORT"
}

function fill_in_n() {
    n_name=$(find "$PLOT_DIR" -regex ".*[0-9]_$1\.png" | sed 's/^.*top\([0-9]\+\)_.*$/\1/' )
    n_name_sed="s/{$2}/$n_name/"
    sed -i "$n_name_sed" "$RAPPORT"
}

function fill_in_table() {
    csv_name=$(find "$PLOT_DIR" -regex ".*[0-9]_$1\.csv" | sed 's/^.*\(top.*\)$/\1/')
    while read -r line; do
        line=$(echo "$line" | tr -d \'\" | sed 's/\//\\\//g;s/\[/\\\| /g;s/, / \\\| /g;s/\]/ \\\|/g;s/\./\\./g;s/\-/\\\-/g')
        line_sed="s/{$2}/$line\n{$2}/"
        sed -i "$line_sed" "$RAPPORT"
    done <"$PARENT_DIR/plots/$csv_name"
    sed -i "s/{$2}//" "$RAPPORT"
}

#
# Variables
#
PARENT_DIR=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"/..
    pwd -P
)
PLOT_DIR="$PARENT_DIR/plots"
RAPPORT="$PARENT_DIR/rapport/rapport-$(date).md"

#
# Script
#

# go to directory of this bash script
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR" || exit


# copy template to rapport
cp "$PARENT_DIR/rapport/template.md" "$RAPPORT"

# fill in begin and endtime of rapport data
BEGIN=$(sed -n '1p' "$PLOT_DIR/dates.txt")
END=$(sed -n '2p' "$PLOT_DIR/dates.txt")

beginsed="s/{starttime}/$BEGIN/"
sed -i "$beginsed" "$RAPPORT"

endsed="s/{endtime}/$END/"
sed -i "$endsed" "$RAPPORT"

sed -i "s/{curtime}/$(date)/" "$RAPPORT"

### fill in the contents ###

# fill in placeholder text
fill_in_placeholder_text

# fill in images
fill_in_image "late_departures" "img_late_dep"
fill_in_image "late_arrivals" "img_late_arr"
fill_in_image "late_trains" "img_late_tr"
fill_in_image "train_cancellations" "img_can_tr"
fill_in_image "cancellations_at_departure" "img_can_dep"

fill_in_image "rel_late_departures" "img_rel_late_dep"
fill_in_image "rel_late_arrivals" "img_rel_late_arr"
fill_in_image "rel_late_trains" "img_rel_late_tr"
fill_in_image "rel_train_cancellations" "img_rel_can_tr"
fill_in_image "rel_cancellations_at_departure" "img_rel_can_dep"

# fill in top n's
fill_in_n "late_departures" "n_late_dep"
fill_in_n "late_arrivals" "n_late_arr"
fill_in_n "late_trains" "n_late_tr"
fill_in_n "train_cancellations" "n_can_tr"
fill_in_n "cancellations_at_departure" "n_can_dep"

fill_in_n "rel_late_departures" "n_rel_late_dep"
fill_in_n "rel_late_arrivals" "n_rel_late_arr"
fill_in_n "rel_late_trains" "n_rel_late_tr"
fill_in_n "rel_train_cancellations" "n_rel_can_tr"
fill_in_n "rel_cancellations_at_departure" "n_rel_can_dep"

# fill in tables
fill_in_table "late_departures" "table_late_dep"
fill_in_table "late_arrivals" "table_late_arr"
fill_in_table "late_trains" "table_late_tr"
fill_in_table "train_cancellations" "table_can_tr"
fill_in_table "cancellations_at_departure" "table_can_dep"

fill_in_table "rel_late_departures" "table_rel_late_dep"
fill_in_table "rel_late_arrivals" "table_rel_late_arr"
fill_in_table "rel_late_trains" "table_rel_late_tr"
fill_in_table "rel_train_cancellations" "table_rel_can_tr"
fill_in_table "rel_cancellations_at_departure" "table_rel_can_dep"

### convert markdown rapport to pdf file ###
pandoc "$RAPPORT" -o "$PARENT_DIR/rapport/rapport.pdf"
