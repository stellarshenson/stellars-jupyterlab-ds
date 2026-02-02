#!/bin/bash
# ============================================================================
# Claude Code Status Line - Fish Prompt Style (Integrated Left)
# ============================================================================
# Layout: [context %][model][git][env][pwd]

input=$(cat)
DIRTRIM=3

# Color palette
CONTEXT_BG="9370DB"
CONTEXT_FG="000000"
MODEL_BG="6A5ACD"
MODEL_FG="FFFFFF"
GIT_BG_CLEAN="229922"
GIT_BG_DIRTY="E87800"
GIT_FG="000000"
ENV_BG_CONDA="FFD966"
ENV_BG_VENV="E8E8E8"
ENV_FG="000000"
PWD_BG="12468A"
PWD_FG="E0E0E0"

SEP_RIGHT=$'\ue0b0'

get_pwd() {
    local pwd_str="${PWD/#$HOME/\~}"
    IFS='/' read -ra parts <<< "$pwd_str"
    local count=${#parts[@]}
    if [ $count -gt $((DIRTRIM + 1)) ]; then
        local start="${parts[0]}"
        local end_start=$((count - DIRTRIM))
        local end=("${parts[@]:$end_start}")
        echo "$start/.../${end[*]}" | tr ' ' '/'
    else
        echo "$pwd_str"
    fi
}

get_env() {
    if [ -n "$VIRTUAL_ENV" ]; then
        # Cache file for venv name lookups (persistent across invocations)
        local cache_file="/tmp/.claude_venv_cache"
        local venv_name=""

        # Check cache - format: "path|name"
        if [ -f "$cache_file" ]; then
            local cached_path cached_name
            IFS='|' read -r cached_path cached_name < "$cache_file"
            if [ "$cached_path" = "$VIRTUAL_ENV" ]; then
                echo "venv:$cached_name"
                return
            fi
        fi

        # Look up friendly name from nb_venv_kernels
        local venv_path="${VIRTUAL_ENV#/home/lab/workspace/}"
        venv_name=$(nb_venv_kernels list --json 2>/dev/null | jq -r --arg path "$venv_path" '.environments[] | select(.path == $path) | .name' 2>/dev/null)

        # Fallback: use parent directory of .venv
        [ -z "$venv_name" ] && venv_name=$(basename "$(dirname "$VIRTUAL_ENV")")

        # Cache the result
        echo "${VIRTUAL_ENV}|${venv_name}" > "$cache_file"

        echo "venv:$venv_name"
    elif [ -n "$CONDA_DEFAULT_ENV" ]; then
        echo "conda:$CONDA_DEFAULT_ENV"
    fi
}

get_git_info() {
    local branch=$(git branch --show-current 2>/dev/null)
    [ -z "$branch" ] && return
    local indicators="" is_dirty=0
    local modified=$(git diff --numstat 2>/dev/null | wc -l)
    [ "$modified" -gt 0 ] && indicators="$indicators !$modified" && is_dirty=1
    local staged=$(git diff --cached --numstat 2>/dev/null | wc -l)
    [ "$staged" -gt 0 ] && indicators="$indicators +$staged" && is_dirty=1
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    [ "$untracked" -gt 0 ] && indicators="$indicators ?$untracked" && is_dirty=1
    echo "$is_dirty:$branch$indicators"
}

# Helper to print segment with transition
# Args: $1=text, $2=bg_hex, $3=fg_hex, $4=prev_bg_hex (empty if first)
print_segment() {
    local text="$1" bg="$2" fg="$3" prev_bg="$4"

    # Chevron transition from previous segment
    if [ -n "$prev_bg" ]; then
        printf "\033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm%s" \
            $((0x${bg:0:2})) $((0x${bg:2:2})) $((0x${bg:4:2})) \
            $((0x${prev_bg:0:2})) $((0x${prev_bg:2:2})) $((0x${prev_bg:4:2})) \
            "$SEP_RIGHT"
    fi

    # Segment content
    printf "\033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm %s " \
        $((0x${bg:0:2})) $((0x${bg:2:2})) $((0x${bg:4:2})) \
        $((0x${fg:0:2})) $((0x${fg:2:2})) $((0x${fg:4:2})) \
        "$text"
}

# Build prompt left to right: [context][model][git][env][pwd]
prompt=""
last_bg=""

# 1. Context percentage
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
if [ -n "$remaining" ]; then
    prompt+=$(print_segment "$(printf "%.0f%%" "$remaining")" "$CONTEXT_BG" "$CONTEXT_FG" "$last_bg")
    last_bg="$CONTEXT_BG"
fi

# 2. Model
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
prompt+=$(print_segment "$model_name" "$MODEL_BG" "$MODEL_FG" "$last_bg")
last_bg="$MODEL_BG"

# 3. Git
git_info=$(get_git_info)
if [ -n "$git_info" ]; then
    is_dirty="${git_info%%:*}"
    git_text="${git_info##*:}"
    [ "$is_dirty" = "1" ] && git_bg="$GIT_BG_DIRTY" || git_bg="$GIT_BG_CLEAN"
    prompt+=$(print_segment "$git_text" "$git_bg" "$GIT_FG" "$last_bg")
    last_bg="$git_bg"
fi

# 4. Environment (conda/venv)
env_info=$(get_env)
if [ -n "$env_info" ]; then
    env_type="${env_info%%:*}"
    env_name="${env_info##*:}"
    [ "$env_type" = "venv" ] && env_bg="$ENV_BG_VENV" || env_bg="$ENV_BG_CONDA"
    prompt+=$(print_segment "$env_name" "$env_bg" "$ENV_FG" "$last_bg")
    last_bg="$env_bg"
fi

# 5. PWD (bold)
pwd_str=$(get_pwd)
# Chevron transition
prompt+=$(printf "\033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm%s" \
    $((0x${PWD_BG:0:2})) $((0x${PWD_BG:2:2})) $((0x${PWD_BG:4:2})) \
    $((0x${last_bg:0:2})) $((0x${last_bg:2:2})) $((0x${last_bg:4:2})) \
    "$SEP_RIGHT")
# PWD content (bold)
prompt+=$(printf "\033[48;2;%d;%d;%dm\033[01;38;2;%d;%d;%dm %s " \
    $((0x${PWD_BG:0:2})) $((0x${PWD_BG:2:2})) $((0x${PWD_BG:4:2})) \
    $((0x${PWD_FG:0:2})) $((0x${PWD_FG:2:2})) $((0x${PWD_FG:4:2})) \
    "$pwd_str")

# Final chevron to terminal background
prompt+=$(printf "\033[00m\033[38;2;%d;%d;%dm%s\033[00m" \
    $((0x${PWD_BG:0:2})) $((0x${PWD_BG:2:2})) $((0x${PWD_BG:4:2})) \
    "$SEP_RIGHT")

echo -n "$prompt"
