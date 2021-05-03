#!/usr/bin/env bash
# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset
#set -x

# fetch previous date from file provided
# or return date for "yesterday" if no file
# provided or a date could not be read from the file.
# Function is tailored for the backup script and will return the
# full date in ISO-8601 format for the first of the month and
# the day of the month for the rest. e.g. 2021-03-01, 02, 03 ...
# Error situations to handle
# - no date file provided (return previous day's date)
# - date file missing or can't be read (return previous day's date)
# - date from file not valid (e.g not "dd" or "yyyy-mm-01")
# - will not validate date beyond formaTR
get_previous_date () {
    if [ $# -gt 0 ] && [ -r "$1" ] # file provided and readable?
    then
        day=$(cat "$1" || day=$(date +%d --date=yesterday))
        # Qualify date: either "nn" or "nnnn-nn-nn"
        if ! [[ $day =~ ^[0-9]{2}$ || \
            $day =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
        then
            day=$(date +%d --date=yesterday )
        fi
    else
        day=$(date +%d --date=yesterday)         # day of month
    fi

    if [ "$day" = "01" ]
    then
        day=$(date +%Y-%m-%d --date=yesterday )
    fi

    echo $day
}

save_previous_date() { # (date, /path/to/file)
    if [ $# -ne 2 ] # file provided? 
    then 
        echo "Args needed: save_previous_date(date pathto/file)"
        exit 1
    fi
    echo "$1" > "$2" || echo "save_previous_date(): unable to write $1 to $2"
}
