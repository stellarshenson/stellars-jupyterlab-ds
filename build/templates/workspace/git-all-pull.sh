#!/bin/bash

OIFS="$IFS" # old separator
IFS=$'\n' # new separator - newline
CURRENT_DIR=$(pwd)

# list repos, but exclude @archive and tutorials
REPOS=$(find . -name '.git' -type d -printf "%p\n" | grep -v 'tutorials' | grep -v '@archive')

# execute git pull
for r in $REPOS;
do
    cd $CURRENT_DIR
    echo "executing pull for $r"
    cd $(realpath $r)
    cd ..
    git pull --rebase
done

# go back
cd $CURRENT_DIR

IFS="$OIFS" # restore separator