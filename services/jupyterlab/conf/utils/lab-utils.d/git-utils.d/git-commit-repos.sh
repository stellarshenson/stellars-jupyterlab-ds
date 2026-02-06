#!/bin/bash
## Runs git commit on all git repos in workspace

OIFS="$IFS" # old separator
IFS=$'\n' # new separator - newline
CURRENT_DIR=$(pwd)
LOGFILE=/tmp/git-workspace.log

# change folder to workspace
cd ${CONDA_USER_WORKSPACE}

# colours
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
NC='\033[0m' # No Color

OK_LOG="nothing to commit, working tree clean"

# list repos, but exclude @archive and tutorials
REPOS=$(find . -name '.git' -type d -printf "%p\n" | grep -v 'tutorials' | grep -v '@archive')

# execute git commit only on repos with changes
declare -i COUNTER=1
for r in $REPOS;
do
    cd $CURRENT_DIR
    cd $(realpath $r)/..
    REPO_NAME=$(basename $(pwd))

    # check if repo has uncommitted changes
    if git diff --quiet && git diff --cached --quiet; then
	echo -e "[$COUNTER] $REPO_NAME - $GRN""clean""$NC"
    else
	echo "[$COUNTER] $REPO_NAME - committing changes..."
	git commit -a 2>&1 | tee $LOGFILE
	GIT_EXITCODE=$?

	if [[ "$GIT_EXITCODE" == 0 ]]; then
	    echo -e "$YEL""COMMITTED""$NC"
	else
	    echo -e "$RED""ERROR""$NC"
	fi
    fi

    # update counter
    let COUNTER=$COUNTER+1
done

# go back
cd $CURRENT_DIR

IFS="$OIFS" # restore separator
