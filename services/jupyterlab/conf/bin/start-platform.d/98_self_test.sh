#!/bin/bash
# ----------------------------------------------------------------------------------------
# Platform Self-Test
#
# Probes the running platform after start and prints one summary table into the
# container log: JupyterLab server, every ENABLED proxied service, the voice
# stack (pulseaudio wiring AND a real tone captured through SoX rec), GPU
# visibility, persistent conda envs, the user env-var chain and the sudo state.
#
# The probes run in a DETACHED background subshell, so the platform start is
# never delayed - the table appears in the log once the server answers (or the
# deadline passes). Works identically standalone and under JupyterHub: only
# localhost ports and files inside the container are probed.
#
# States: OK (probe passed), FAIL (enabled but not answering), off (disabled
# by its ENABLE_SERVICE_* knob), n/a (not applicable on this host, e.g. no GPU).
# ----------------------------------------------------------------------------------------

(
    DEADLINE=$((SECONDS + 180))

    probe_http() { curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$1/"; }

    wait_http() {
        while (( SECONDS < DEADLINE )); do
            probe_http "$1" && return 0
            sleep 3
        done
        return 1
    }

    ROWS=()
    OK_N=0; FAIL_N=0
    add_row() { # name, state, detail
        ROWS+=("$1|$2|$3")
        case "$2" in OK) OK_N=$((OK_N+1));; FAIL) FAIL_N=$((FAIL_N+1));; esac
    }

    # deployment mode
    if [[ -n ${JUPYTERHUB_USER} ]]; then
        add_row "deployment mode" "OK" "jupyterhub (user: ${JUPYTERHUB_USER})"
    else
        add_row "deployment mode" "OK" "standalone"
    fi

    # jupyterlab server - everything else boots alongside it
    if wait_http 8888; then
        add_row "jupyterlab server :8888" "OK" "answering"
    else
        add_row "jupyterlab server :8888" "FAIL" "no answer within deadline"
    fi

    # proxied services, each gated by its knob (defaults mirror the launch hooks)
    MLFLOW_PORT=${MLFLOW_SERVER_PORT:-${MLFLOW_PORT:-5000}}
    if [[ ${ENABLE_SERVICE_MLFLOW} != 1 ]]; then
        add_row "mlflow :${MLFLOW_PORT}" "off" "ENABLE_SERVICE_MLFLOW != 1"
    elif wait_http "${MLFLOW_PORT}"; then
        add_row "mlflow :${MLFLOW_PORT}" "OK" "answering (proxy path /mlflow)"
    else
        add_row "mlflow :${MLFLOW_PORT}" "FAIL" "enabled but not answering - see /var/log/mlflow.log"
    fi

    TB_PORT=${TENSORBOARD_PORT:-6006}
    if [[ ${ENABLE_SERVICE_TENSORBOARD} != 1 ]]; then
        add_row "tensorboard :${TB_PORT}" "off" "ENABLE_SERVICE_TENSORBOARD != 1"
    elif wait_http "${TB_PORT}"; then
        add_row "tensorboard :${TB_PORT}" "OK" "answering (proxy path /tensorboard)"
    else
        add_row "tensorboard :${TB_PORT}" "FAIL" "enabled but not answering - see /var/log/tensorboard.log"
    fi

    if [[ ${ENABLE_SERVICE_RESOURCES_MONITOR} != 1 ]]; then
        add_row "resources monitor :7681" "off" "ENABLE_SERVICE_RESOURCES_MONITOR != 1"
    elif wait_http 7681; then
        add_row "resources monitor :7681" "OK" "answering (proxy path /rmonitor)"
    else
        add_row "resources monitor :7681" "FAIL" "enabled but not answering"
    fi

    # sound system - a running daemon is NOT enough (a stale FIFO once let the
    # daemon run with the voicein source dead), so probe the actual wiring and
    # then the full user-app path: a synthesized tone pushed through the FIFO
    # must come back out of SoX rec (what Claude Code /voice runs) with real
    # amplitude. The tone fits the 64K pipe buffer, so the write never blocks.
    if [[ ${ENABLE_SERVICE_PULSEAUDIO} != 1 ]]; then
        add_row "pulseaudio" "off" "ENABLE_SERVICE_PULSEAUDIO != 1"
        add_row "voice capture (rec)" "off" "ENABLE_SERVICE_PULSEAUDIO != 1"
    elif ! PULSE_RUNTIME_PATH=/tmp/pulse-lab pactl info >/dev/null 2>&1; then
        add_row "pulseaudio" "FAIL" "daemon not reachable - see /var/log/pulseaudio.log"
        add_row "voice capture (rec)" "n/a" "daemon down"
    elif ! PULSE_RUNTIME_PATH=/tmp/pulse-lab pactl list short sources 2>/dev/null | grep -q 'voicein' \
         || [[ ! -p /run/voice/pulseaudio.fifo ]]; then
        add_row "pulseaudio" "FAIL" "source 'voicein' not connected - see /var/log/pulseaudio.log"
        add_row "voice capture (rec)" "n/a" "source missing"
    else
        add_row "pulseaudio" "OK" "daemon up, source 'voicein' on /run/voice fifo"
        TONE=$(mktemp); CAP=$(mktemp --suffix=.wav)
        sox -n -t raw -r 16000 -c 1 -b 16 -e signed-integer "${TONE}" synth 0.5 sine 440 2>/dev/null
        cat "${TONE}" > /run/voice/pulseaudio.fifo 2>/dev/null &
        PEAK=$(AUDIODRIVER=pulseaudio PULSE_RUNTIME_PATH=/tmp/pulse-lab timeout 15 rec -q "${CAP}" trim 0 0.3 2>/dev/null \
               && sox "${CAP}" -n stat 2>&1 | awk '/^Maximum amplitude/{print $3}')
        rm -f "${TONE}" "${CAP}"
        if awk -v p="${PEAK:-0}" 'BEGIN{exit !(p >= 0.05)}'; then
            add_row "voice capture (rec)" "OK" "tone captured via rec (peak ${PEAK})"
        else
            add_row "voice capture (rec)" "FAIL" "rec captured no signal - see /var/log/pulseaudio.log"
        fi
    fi

    # gpu visibility - absence is a valid CPU deployment, not a failure
    GPU_LIST=$(nvidia-smi -L 2>/dev/null)
    if [[ -n ${GPU_LIST} ]]; then
        GPU_N=$(wc -l <<< "${GPU_LIST}")
        add_row "gpu" "OK" "${GPU_N}x $(head -1 <<< "${GPU_LIST}" | sed 's/GPU 0: //; s/ (UUID.*//')"
    else
        add_row "gpu" "n/a" "no NVIDIA GPU visible"
    fi

    # persistent user conda envs (07_conda_persistent_envs.sh) - anchored so a
    # commented-out "# envs_dirs:" never counts, and the detail only claims the
    # hook's path when the ACTIVE key's entries actually carry it; a
    # user-managed envs_dirs pointing elsewhere is a valid setup, not this one
    if grep -qs '^envs_dirs' "${HOME}/.condarc"; then
        if grep -A2 '^envs_dirs' "${HOME}/.condarc" | grep -q '\.conda/envs'; then
            add_row "persistent conda envs" "OK" "~/.condarc: envs -> ~/.conda/envs"
        else
            add_row "persistent conda envs" "OK" "envs_dirs configured (user-managed)"
        fi
    else
        add_row "persistent conda envs" "FAIL" "~/.condarc missing envs_dirs"
    fi

    # user env-var chain (~/.local/environment.env sourced by ~/.profile);
    # the wiring is checked in BOTH lock states - when locked the store still
    # feeds login shells (the manual channel), so broken wiring always FAILs.
    # A valid locked state only changes the detail, surfacing the sudo bypass
    if ! grep -qs 'environment\.env' "${HOME}/.profile"; then
        add_row "env-var chain" "FAIL" "~/.profile does not source the env store"
    elif [[ ${JUPYTERLAB_USER_ENV_ENABLE:-1} == 0 ]]; then
        if [[ ${JUPYTERLAB_SUDO_ENABLE:-1} != 0 ]]; then
            add_row "env-var chain" "OK" "store locked; WARNING: sudo enabled - lock bypassable"
        else
            add_row "env-var chain" "OK" "user env store locked (JUPYTERLAB_USER_ENV_ENABLE=0)"
        fi
    else
        add_row "env-var chain" "OK" "~/.profile sources ~/.local/environment.env"
    fi

    # sudo state - informational, both states are valid configurations
    if sudo -n true 2>/dev/null; then
        add_row "sudo" "OK" "enabled"
    else
        add_row "sudo" "OK" "disabled (JUPYTERLAB_SUDO_ENABLE=${JUPYTERLAB_SUDO_ENABLE:-1})"
    fi

    # render the table - cells are padded BEFORE coloring, so alignment holds.
    # docker logs passes ANSI through to the viewer's terminal; NO_COLOR opts out.
    if [[ -z ${NO_COLOR} ]]; then
        C_OK=$'\e[32m'; C_FAIL=$'\e[1;31m'; C_DIM=$'\e[2m'
        C_TITLE=$'\e[1;36m'; C_BORDER=$'\e[36m'; C_R=$'\e[0m'
    else
        C_OK=; C_FAIL=; C_DIM=; C_TITLE=; C_BORDER=; C_R=
    fi
    # detail cell holds 60 chars - the longest FAIL messages end in the log
    # path the user must copy, which a narrower cell would clip
    BAR=$(printf '─%.0s' $(seq 1 94))
    echo ""
    echo "${C_BORDER}┌${BAR}┐${C_R}"
    printf "${C_BORDER}│${C_R} ${C_TITLE}%-92s${C_R} ${C_BORDER}│${C_R}\n" "platform self-test"
    echo "${C_BORDER}├${BAR}┤${C_R}"
    for row in "${ROWS[@]}"; do
        IFS='|' read -r NAME STATE DETAIL <<< "${row}"
        CELL=$(printf '%-4s' "${STATE}")
        DCELL=$(printf '%-60s' "${DETAIL:0:60}")
        case "${STATE}" in
            OK)   CELL="${C_OK}${CELL}${C_R}" ;;
            FAIL) CELL="${C_FAIL}${CELL}${C_R}"; DCELL="${C_FAIL}${DCELL}${C_R}" ;;
            *)    CELL="${C_DIM}${CELL}${C_R}";  DCELL="${C_DIM}${DCELL}${C_R}" ;;
        esac
        printf "${C_BORDER}│${C_R} %-26s %s %s ${C_BORDER}│${C_R}\n" "${NAME}" "${CELL}" "${DCELL}"
    done
    echo "${C_BORDER}└${BAR}┘${C_R}"
    if [[ ${FAIL_N} -eq 0 ]]; then
        log_info "self-test complete: ${OK_N} ok, 0 failed"
    else
        log_error "self-test complete: ${OK_N} ok, ${FAIL_N} FAILED"
    fi
) &

# EOF
