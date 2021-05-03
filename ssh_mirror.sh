#!/bin/bash

# script for backing up personal $HOME/Document directory for a  user
# fork of mirror.sh that uses ssh to reach the remote instead of 
# relying on NFS mounts. The destination will be modified to save the
# files to the same destination and it is assumed that the organization
# of files on the destination are the same for all backup hosts.
# see http://www.admin-magazine.com/Articles/Using-rsync-for-Backups for
# a review of rsync flags and 
# https://askubuntu.com/questions/105848/rsync-between-two-computers-on-lan
# for rsync across ssh
#
# script also requires ssh public key copied to remote to avoid
# password prompting.

# parse args using "Straight Bash Space Separated" 
# from https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

# deploy instructions
# cp prev_date.sh ssh_mirror.sh /home/$USER/bin
# sudo mkdir /var/local/ssh_mirror.sh/
# sudo chown $USER.$USER /var/local/ssh_mirror.sh/

set -o errexit
set -o nounset
set -o pipefail

VER="0.3.1"

. "$(dirname $0)/prev_date.sh"

function Usage {
    echo "Usage: $0 [-h host] [-a local_alias] [-?] [-v] [dir dir ... dir]" 
    echo "  [-h host] optionally specify host to send backups to"
    echo "  [-a local_alias] optionally specify host name used to store"
    echo "                   backup on remote (for hosts that use different"
    echo "                   host names at times"
    echo "  [-r dir] directory to be prepended to the destination"
    echo "  [dir dir ... dir] directories (relative to \$HOME) to backup"
    echo "  [-?] print this message and exit"
    echo "  [-v] print version ($VER) and exit"
    echo
    echo "defaults: -h oak -a" "$(hostname)" "Documents"
    exit 1
}

CMD=("$@") # save command line


# default hostname to use for the destination directory
USEHOST=$(hostname)
REMOTE_HOST="oak"
DIRS="Documents"
ROOT=""

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h)
        if [ -z "$2" ]; then 
            Usage 
        else 
            REMOTE_HOST="$2"
        fi

        shift 2 # past argument and value
        ;;

    -a)
        if [ -z "$2" ]; then 
            Usage 
        else 
            USEHOST="$2"
        fi

        shift 2 # past argument and value
        ;;

    -r)
        if [ -z "$2" ]; then
            Usage
        else
            ROOT="$2"
        fi

        shift 2 # past argument and value
        ;;
    -v)
         echo "Version:$VER"
         exit 1
        ;;

    -?)
         Usage
        ;;

     *)
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
esac
done

# set default directory if none specified
if [ ${#POSITIONAL[@]} -eq 0 ]; then
    POSITIONAL[0]="Documents"
fi

set -- "${POSITIONAL[@]}" # restore positional parameters

readonly PREV_DATE_FILE="/var/local/ssh_mirror.sh/$REMOTE_HOST"

echo "Command line:\" $0 ${CMD[*]}\""
echo "REMOTE_HOST $REMOTE_HOST"
echo "USEHOST $USEHOST"
echo "DIRS $DIRS"
echo "PREV_DATE_FILE $PREV_DATE_FILE"


for i in "$@"
do
    echo "  $i"
done

## branch locates the destination of the 
branch="$LOGNAME/${USEHOST}"
echo branch="$branch"


day=$(date +%d)         # day of month
prev_date=$(get_previous_date $PREV_DATE_FILE)
echo "prev_date $prev_date"
if [ "$day" = "01" ]
then
    day=$(date +%Y-%m-%d)
    incremental=""
else
    # incremental="--link-dest=${ROOT}/redwood/$branch/`date +%Y-%m-01`"
    # use previous day for link-dest
    #dest_day=${day#0}   # interpret as decimal
    #((dest_day-=1))     # previous day
    #dest_day=$(printf "%02d" $dest_day)
    # shellcheck disable=SC2029
    incremental="--link-dest=${ROOT}/redwood/$branch/$prev_date"
fi
    full_incremental=""

for d in "$@" 
do
    if [ -n "$incremental" ]
    then
        full_incremental=${incremental}/$d
    fi
    # shellcheck disable=SC2029
    ssh "${LOGNAME}@${REMOTE_HOST}" "mkdir -p ${ROOT}/redwood/$branch/$day/"
    rsync_cmd="/usr/bin/rsync -azXAS --delete -v \
        $full_incremental --exclude='.git/*' \
        /home/$LOGNAME/$d/ \
        ${REMOTE_HOST}:${ROOT}/redwood/$branch/$day/$d"
    echo "$rsync_cmd"
    # exit

    echo "starting at " "$(date)"

    $rsync_cmd
done

save_previous_date "$day" "$PREV_DATE_FILE"

df

echo "ending at " "$(date)"
