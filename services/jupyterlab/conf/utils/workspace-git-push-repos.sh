#!/bin/bash

OIFS="$IFS" # old separator
IFS=$'\n' # new separator - newline
CURRENT_DIR=$(pwd)
LOGFILE=/tmp/git-workspace.log
OK_LOG="Everything up-to-date"

# colours
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
NC='\033[0m' # No Color

# list repos, but exclude @archive and tutorials
REPOS=$(find . -name '.git' -type d -printf "%p\n" | grep -v 'tutorials' | grep -v '@archive')

# execute git pull
declare -i COUNTER=1
for r in $REPOS;
do
    cd $CURRENT_DIR
    echo "[$COUNTER] executing push for $r"
    cd $(realpath $r)
    cd ..
    git push 2>&1 | tee $LOGFILE
    GIT_EXITCODE=$?

    # check logs and exit codes
    cat $LOGFILE | grep $OK_LOG > /dev/null
    LOGCHECK_EXITCODE=$?
    if [[ "$LOGCHECK_EXITCODE" == 0 && "$GIT_EXITCODE" == 0 ]]; then
	echo -e "$GRN""OK""$NC"
    fi
    if [[ "$LOGCHECK_EXITCODE" != 0 && "$GIT_EXITCODE" == 0 ]]; then
	echo -e "$YEL""VERIFY""$NC"
    fi
    if [[ "$GIT_EXITCODE" != 0 ]]; then
	echo -e "$RED""ERROR""$NC"
    fi

    let COUNTER=$COUNTER+1
done

# go back
cd $CURRENT_DIR

IFS="$OIFS" # restore separator
