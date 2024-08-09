#!/bin/bash
## in your Dockerfile
# COPY conda_run.sh /conda_run.sh
# RUN chmod +x /conda_run.sh
# SHELL ["/conda_run.sh", "/bin/bash", "-c"]

## usage
## CONDA_DEFAULT_ENV=FOO command arg1 arg2
## or 
## command arg1 arg2

## The SHELL ["/run.sh"] command passes everything in the RUN stanza as a single string
## There may be a better way to unpack it. We must unpack before conda setup
IFS=' ' read -ra ARGS <<< "${1}"
## FIRST=`eval echo ${ARGS[@]::1}`
#before was: 
FIRST=${ARGS[@]::1}

## setup conda - it will overwrite all conda variables
__conda_setup="$($CONDA_CMD 'shell.bash' 'hook' 2> /dev/null)"
eval "$__conda_setup"
unset __conda_setup

## debugging, uncomment to see the args passed into this script
#echo ...
#echo "${1}"
#echo "${ARGS[@]}"
#echo "${@}"
#echo "First: ${FIRST}"
#echo ...

## parse the possible first argument for setting conda env
## This is not a "true environment variable", we just emulate the syntax for essentially syntactic sugar in Dockerfiles
if [[ "$( echo ${FIRST}| cut -c-18)" == "CONDA_DEFAULT_ENV=" ]]; then
        _CONDA_DEFAULT_ENV=$(echo "${FIRST}" | cut -c19-)
  EXEC_ARGS=$(echo ${ARGS[@]:1})
else
  _CONDA_DEFAULT_ENV=base
  EXEC_ARGS="$(echo ${ARGS[*]})"
fi

##logging, this is just for debugging, you can enable this to sanity check or see what is happening
>&2 echo "ENV: ${_CONDA_DEFAULT_ENV}, COMMAND: ${EXEC_ARGS}"
conda activate "${_CONDA_DEFAULT_ENV}"
/bin/bash -c "${EXEC_ARGS}"

# EOF
