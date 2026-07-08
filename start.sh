#!/bin/sh
CURRENT_FILE=$(readlink -f "$0")
CURRENT_DIR=$(dirname "$CURRENT_FILE")
cd "$CURRENT_DIR" || exit 1

ENV_FILE=".env"

# fail early with a clear message when docker is not up - compose errors are cryptic
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: docker is not running or not reachable - start Docker (or Docker/Rancher Desktop) and re-run." >&2
    exit 1
fi

# First start: no auth token in .env yet -> ask for a password and save it.
# Stored as JUPYTERLAB_SERVER_TOKEN, it becomes the password the JupyterLab
# login page asks for (it is never placed in the URL). An EMPTY value counts
# as unset: jupyter would autogenerate a random token and lock the user out.
# The quoted-empty forms '' / "" also parse to an empty token - treat them as
# unset. Value extracted last-wins with CR/whitespace stripped, so a CRLF .env
# written on Windows (start.bat) or a hand-emptied value with stray spaces or a
# trailing comment cannot slip past the guard (compose parses all of them to an
# EMPTY token). Stripping inner spaces is fine here - the value is only tested
# for emptiness, never used; worst case an exotic token re-prompts (fail-safe)
TOKEN_VALUE=`grep '^JUPYTERLAB_SERVER_TOKEN=' "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d " \t\r"`
case "$TOKEN_VALUE" in
""|"''"|'""'|"#"*) TOKEN_UNSET=1 ;;
*) TOKEN_UNSET=0 ;;
esac
if [ "$TOKEN_UNSET" = 1 ]; then
    echo "First start - set the initial password for JupyterLab access."
    echo "This is the initial password; change it later in $ENV_FILE (restart to apply)."
    trap 'stty echo 2>/dev/null || true' EXIT INT TERM # never leave the terminal with echo off
    JUPYTERLAB_PASSWORD=""
    while [ -z "$JUPYTERLAB_PASSWORD" ]; do
        printf "Enter a password: "
        stty -echo 2>/dev/null || true
        if ! read -r JUPYTERLAB_PASSWORD; then # stdin EOF (non-interactive run) - abort instead of spinning
            stty echo 2>/dev/null || true
            echo
            echo "ERROR: no interactive input - add JUPYTERLAB_SERVER_TOKEN=<password> to $ENV_FILE and re-run." >&2
            exit 1
        fi
        stty echo 2>/dev/null || true
        echo
        case "$JUPYTERLAB_PASSWORD" in *"'"*)
            echo "Single quotes (') are not supported in the password - please choose another."
            JUPYTERLAB_PASSWORD="" ;;
        esac
    done
    if [ -f "$ENV_FILE" ]; then
        sed -i "/^JUPYTERLAB_SERVER_TOKEN=\(''\|\"\"\)\{0,1\}\r\{0,1\}\$/d" "$ENV_FILE" 2>/dev/null || true # drop an empty leftover (bare or quoted-empty, CRLF-tolerant) so one key remains
        [ -n "$(tail -c1 "$ENV_FILE" 2>/dev/null)" ] && echo >> "$ENV_FILE" # missing trailing newline would glue the keys together
    fi
    # single-quoted so $, #, spaces and quotes survive compose dotenv parsing verbatim
    printf "JUPYTERLAB_SERVER_TOKEN='%s'\n" "$JUPYTERLAB_PASSWORD" >> "$ENV_FILE"
    chmod 600 "$ENV_FILE" 2>/dev/null || true # holds the password - keep it private
    echo "Initial password saved to $ENV_FILE (key JUPYTERLAB_SERVER_TOKEN)."
fi

# GPU: needs BOTH a working driver (nvidia-smi) and docker's nvidia runtime
# (nvidia-container-toolkit) - with only the driver, the GPU overlay would fail
COMPOSE_FILES="-f compose.yml"
if command -v nvidia-smi > /dev/null 2>&1 && nvidia-smi > /dev/null 2>&1; then
    if docker info --format '{{json .Runtimes}}' 2>/dev/null | grep -qi nvidia; then
        echo "Nvidia GPU found."
        COMPOSE_FILES="-f compose.yml -f compose-gpu.yml"
    else
        echo "WARNING: NVIDIA GPU detected but docker has no nvidia runtime (install nvidia-container-toolkit) - starting without GPU."
    fi
else
    echo "Nvidia GPU not available."
fi

if ! docker compose --env-file .env.default --env-file .env $COMPOSE_FILES up --no-recreate --no-build -d; then
    echo
    echo "ERROR: docker compose up failed - see the messages above (port conflict, missing image, invalid .env)." >&2
    printf "Press Enter to close this window..."
    read -r dummy
    exit 1
fi

# Access information: hosts derive from COMPOSE_PROJECT_NAME (.env overrides
# .env.default; tail -1 = last-wins on duplicated keys, matching compose dotenv;
# tr -d '\r' = a CRLF .env written on Windows must not garble the URL)
PROJECT_NAME=`grep '^COMPOSE_PROJECT_NAME=' "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2 | tr -d '\r'`
[ -z "$PROJECT_NAME" ] && PROJECT_NAME=`grep '^COMPOSE_PROJECT_NAME=' .env.default 2>/dev/null | tail -1 | cut -d= -f2 | tr -d '\r'`
[ -z "$PROJECT_NAME" ] && PROJECT_NAME="stellars-jupyterlab-ds"
LAB_PORT=`grep '^LAB_PORT=' "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2 | tr -d '\r'`
[ -z "$LAB_PORT" ] && LAB_PORT=`grep '^LAB_PORT=' .env.default 2>/dev/null | tail -1 | cut -d= -f2 | tr -d '\r'`
[ -z "$LAB_PORT" ] && LAB_PORT=443
ACCESS_URL="https://lab.$PROJECT_NAME.localhost"
[ "$LAB_PORT" != "443" ] && ACCESS_URL="$ACCESS_URL:$LAB_PORT"
echo
echo "JupyterLab is starting."
echo "Access URL: $ACCESS_URL"
echo "Log in with the password you set (it is not in the URL)."
echo "The password is stored in $CURRENT_DIR/$ENV_FILE (key JUPYTERLAB_SERVER_TOKEN)."
echo "Note: changes to $ENV_FILE apply after ./stop.sh && ./start.sh (running containers are not recreated)."
echo
printf "Press Enter to close this window..."
read -r dummy

# EOF
