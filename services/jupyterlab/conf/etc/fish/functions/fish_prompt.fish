# ============================================================================
# Stellars JupyterLab DS Fish Prompt
# ============================================================================
#
# Standalone powerline-style prompt for Fish shell with no external dependencies.
# Designed for Stellars JupyterLab DS container environment.
#
# ============================================================================
# Visual Design
# ============================================================================
#
# PROMPT LAYOUT
# -------------
#
#   LEFT                                                          RIGHT
#   [env][pwd]                                     [git][error] [duration]
#
#
# LEFT PROMPT STRUCTURE
# ---------------------
#
#   With environment:
#   ┌────────────┐┌──────────────────┐
#   │ env name   ││ ~/path/to/dir    │
#   └────────────┘└──────────────────┘
#
#   Without environment:
#   ┌──────────────────┐
#   │ ~/path/to/dir    │
#   └──────────────────┘
#
#   Chevron: U+E0B0  (right-pointing, cuts into next segment)
#
#
# RIGHT PROMPT STRUCTURE
# ----------------------
#
#   Pattern 1 - Git only:
#   ┌─────────────────┐
#   │ main !3 +1 ?2   │
#   └─────────────────┘
#
#   Pattern 2 - Git + Error:
#   ┌─────────────────┬───────┐
#   │ main !3 +1 ?2   │ 127   │
#   └─────────────────┴───────┘
#                     ^ error cuts into git
#
#   Pattern 3 - Git + Duration:
#   ┌─────────────────┐ ┌───────┐
#   │ main !3 +1 ?2   │ │ 8s    │
#   └─────────────────┘ └───────┘
#                     ^ square butt, space, duration
#
#   Pattern 4 - Git + Error + Duration:
#   ┌─────────────────┬───────┐ ┌───────┐
#   │ main !3 +1 ?2   │ 127   │ │ 8s    │
#   └─────────────────┴───────┘ └───────┘
#                     ^       ^ square butt, space, duration
#                     error cuts into git
#
#   Chevron: U+E0B2  (left-pointing, cuts into previous segment)
#
#
# COLOR PALETTE
# -------------
#
#   Segment              Background    Foreground    Notes
#   ─────────────────────────────────────────────────────────────────
#   Environment (conda)  #FFD966       #000000       Pale yellow, black text
#   Environment (venv)   #E8E8E8       #000000       Pale white, black text
#   PWD                  #2266AA       #E0E0E0       Blue, light gray text (bold)
#   Git (clean)          #228B22       #000000       Forest green, black text
#   Git (dirty)          #E87800       #000000       Orange, black text
#   Error                #CC0000       #FFFFFF       Red, white text
#   Duration             #FFB000       #000000       Amber yellow, black text
#
#
# CHEVRON TRANSITIONS
# -------------------
#
#   Left prompt (right-pointing ):
#   - Chevron fg = previous segment bg
#   - Chevron bg = next segment bg
#   - Creates: previous segment "flows into" next
#
#   Right prompt (left-pointing ):
#   - Chevron fg = current segment bg
#   - Chevron bg = previous segment bg (or terminal default)
#   - Creates: current segment "cuts into" previous
#
#   Connected segments: chevron drawn on previous bg with current fg
#   Square butt: segment ends, reset to normal, space before next
#
#
# TEXT STYLING
# ------------
#
#   PWD text:       Bold (-o flag)
#   All other text: Normal weight
#   Padding:        Single space before and after text in each segment
#
#
# POWERLINE GLYPHS
# ----------------
#
#   Character    Unicode    Description
#   ─────────────────────────────────────────
#              U+E0B0     Right-pointing separator (left prompt)
#              U+E0B2     Left-pointing separator (right prompt)
#
#   Requires: Powerline-compatible font (e.g., Nerd Fonts, Powerline patched)
#
#
# ============================================================================
# Features
# ============================================================================
#
#   - Environment display (conda/venv) with automatic detection
#   - Virtual env names resolved via nb_venv_kernels (falls back to directory name)
#   - PWD with bash-style DIRTRIM abbreviation (~/.../last/three/dirs)
#   - Git branch with status indicators on right prompt
#   - Error status display (exit code when non-zero)
#   - Command duration display (when exceeding threshold)
#   - Powerline chevron separators
#   - Color differentiation: yellow for conda, pale white for venv
#   - Dirty/clean git status with orange/green backgrounds
#
# Git Status Indicators (in order):
#   !N    N files with uncommitted changes (modified tracked files)
#   +N    N files staged for commit
#   ?N    N untracked files
#   ↑N    N commits ahead of upstream
#   ↓N    N commits behind upstream
#
# ============================================================================
# Installation
# ============================================================================
#
#   1. Place this file in /etc/fish/functions/fish_prompt.fish
#   2. Add to config.fish:
#        source /etc/fish/functions/fish_prompt.fish
#        set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
#        set -e CONDA_PROMPT_MODIFIER
#
# Dependencies:
#   - nb_venv_kernels (optional, for friendly venv names)
#   - jq (optional, for parsing nb_venv_kernels JSON)
#   - git (for branch/status display)
#   - Powerline-compatible font (for chevron characters)
#
# ============================================================================
# ----------------------------------------------------------------------------
# Configuration Variables
# ----------------------------------------------------------------------------
# Override these in config.fish before sourcing this file to customize colors.
# All colors are 6-digit hex values (RRGGBB).

# PWD abbreviation - number of trailing directories to show
set -q stellars_prompt_dirtrim || set -g stellars_prompt_dirtrim 3

# Environment segment colors
set -q stellars_prompt_env_bg_conda || set -g stellars_prompt_env_bg_conda FFD966  # Pale yellow
set -q stellars_prompt_env_bg_venv || set -g stellars_prompt_env_bg_venv E8E8E8    # Pale white/gray
set -q stellars_prompt_env_fg || set -g stellars_prompt_env_fg 000000              # Black text

# PWD segment colors
set -q stellars_prompt_pwd_bg || set -g stellars_prompt_pwd_bg 2266AA              # Blue
set -q stellars_prompt_pwd_fg || set -g stellars_prompt_pwd_fg E0E0E0              # Light gray text

# Git segment colors
set -q stellars_prompt_git_bg_clean || set -g stellars_prompt_git_bg_clean 229922  # Forest green
set -q stellars_prompt_git_bg_dirty || set -g stellars_prompt_git_bg_dirty E87800  # Orange
set -q stellars_prompt_git_fg || set -g stellars_prompt_git_fg 000000              # Black text

# Error segment colors (shown when last command failed)
set -q stellars_prompt_error_bg || set -g stellars_prompt_error_bg DD0000          # Red
set -q stellars_prompt_error_fg || set -g stellars_prompt_error_fg FFFFFF          # White text

# Duration segment colors (shown when command exceeds threshold)
set -q stellars_prompt_duration_bg || set -g stellars_prompt_duration_bg FFC500    # Yellow
set -q stellars_prompt_duration_fg || set -g stellars_prompt_duration_fg 000000    # Black text
set -q stellars_prompt_duration_threshold || set -g stellars_prompt_duration_threshold 3000  # 3 seconds in ms

# ----------------------------------------------------------------------------
# Helper Functions
# ----------------------------------------------------------------------------

# __stellars_pwd - Get abbreviated PWD (DIRTRIM style)
# 
# Replaces $HOME with ~ and truncates long paths to show only the last N
# directories (controlled by stellars_prompt_dirtrim). Middle directories
# are replaced with "...".
#
# Example: /home/user/workspace/project/src/components -> ~/.../src/components
#
function __stellars_pwd
    set -l pwd_str (string replace -r "^$HOME" '~' -- $PWD)
    set -l parts (string split '/' -- $pwd_str)
    set -l count (count $parts)

    if test $count -gt (math $stellars_prompt_dirtrim + 1)
        set -l start $parts[1]
        set -l end_start (math $count - $stellars_prompt_dirtrim + 1)
        set -l end $parts[$end_start..]
        echo "$start/.../"(string join '/' -- $end)
    else
        echo $pwd_str
    end
end

# __stellars_env - Get current environment name
#
# Returns environment info in format "type:name" where type is "conda" or "venv".
# Priority: VIRTUAL_ENV takes precedence over CONDA_DEFAULT_ENV.
#
# For virtual environments, attempts to resolve friendly name via nb_venv_kernels.
# Falls back to parent directory name if nb_venv_kernels unavailable or env not found.
# Caches resolved venv names for session duration to avoid repeated nb_venv_kernels calls.
#
# Returns: "conda:base", "venv:myproject", etc. Empty if no env active.
#
function __stellars_env
    # Suppress standard venv prompt modifier
    set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

    if set -q VIRTUAL_ENV
        # Check cache first - keyed by VIRTUAL_ENV path
        if set -q __stellars_venv_cache_path
            if test "$__stellars_venv_cache_path" = "$VIRTUAL_ENV"
                echo "venv:$__stellars_venv_cache_name"
                return
            end
        end

        # Look up friendly name from nb_venv_kernels using JSON output
        set -l venv_path (string replace "/home/lab/workspace/" "" -- $VIRTUAL_ENV)
        set -l venv_name (nb_venv_kernels list --json 2>/dev/null | jq -r --arg path "$venv_path" '.environments[] | select(.path == $path) | .name' 2>/dev/null)

        # Fallback: use parent directory of .venv
        if test -z "$venv_name"
            set venv_name (basename (dirname $VIRTUAL_ENV))
        end

        # Cache the result
        set -g __stellars_venv_cache_path $VIRTUAL_ENV
        set -g __stellars_venv_cache_name $venv_name

        echo "venv:$venv_name"
    else if set -q CONDA_DEFAULT_ENV
        # Clear venv cache when not in venv
        set -e __stellars_venv_cache_path
        set -e __stellars_venv_cache_name
        echo "conda:$CONDA_DEFAULT_ENV"
    else
        # Clear venv cache when no env active
        set -e __stellars_venv_cache_path
        set -e __stellars_venv_cache_name
    end
end

# __stellars_duration - Format command duration for display
#
# Takes saved duration in milliseconds and formats it as human-readable:
#   - Under 1 minute: Xs (e.g., "5s", "45s")
#   - 1-60 minutes: Xm Ys (e.g., "2m 30s")
#   - Over 60 minutes: Xh Ym (e.g., "1h 15m")
#
# Returns empty string if duration is below threshold.
#
function __stellars_duration
    if test -z "$__stellars_last_duration"
        return
    end
    
    if test $__stellars_last_duration -lt $stellars_prompt_duration_threshold
        return
    end
    
    set -l seconds (math --scale=0 "$__stellars_last_duration / 1000")
    set -l minutes (math --scale=0 "$seconds / 60")
    set -l hours (math --scale=0 "$minutes / 60")
    
    if test $hours -gt 0
        set -l remaining_mins (math --scale=0 "$minutes % 60")
        echo "$hours"h" $remaining_mins"m
    else if test $minutes -gt 0
        set -l remaining_secs (math --scale=0 "$seconds % 60")
        echo "$minutes"m" $remaining_secs"s
    else
        echo "$seconds"s
    end
end

# __stellars_git_info - Get git branch and status information
#
# Returns git info in format "is_dirty:branch indicators" where:
#   - is_dirty: 0 for clean, 1 for dirty (determines background color)
#   - branch: current branch name
#   - indicators: space-separated status indicators
#
# Indicators (in order of appearance):
#   !N    N files with uncommitted changes (modified tracked files)
#   +N    N files staged for commit
#   ?N    N untracked files
#   ↑N    N commits ahead of upstream
#   ↓N    N commits behind upstream
#
# Returns empty string if not in a git repository.
#
function __stellars_git_info
    set -l branch (git branch --show-current 2>/dev/null)
    if test -z "$branch"
        return
    end
    
    set -l indicators ""
    set -l is_dirty 0
    
    # Check for uncommitted changes (count modified tracked files)
    set -l modified_count (git diff --numstat 2>/dev/null | count)
    if test $modified_count -gt 0
        set indicators "$indicators !$modified_count"
        set is_dirty 1
    end
    
    # Check for staged changes (count files)
    set -l staged_count (git diff --cached --numstat 2>/dev/null | count)
    if test $staged_count -gt 0
        set indicators "$indicators +$staged_count"
        set is_dirty 1
    end
    
    # Check for untracked files (count)
    set -l untracked_count (git ls-files --others --exclude-standard 2>/dev/null | count)
    if test $untracked_count -gt 0
        set indicators "$indicators ?$untracked_count"
        set is_dirty 1
    end
    
    # Check ahead/behind upstream
    set -l upstream (git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    if test -n "$upstream"
        set -l counts (git rev-list --left-right --count HEAD...$upstream 2>/dev/null)
        set -l ahead_count (echo $counts | awk '{print $1}')
        set -l behind_count (echo $counts | awk '{print $2}')
        if test "$ahead_count" -gt 0
            set indicators "$indicators ↑$ahead_count"
        end
        if test "$behind_count" -gt 0
            set indicators "$indicators ↓$behind_count"
        end
    end
    
    echo "$is_dirty:$branch$indicators"
end

# ----------------------------------------------------------------------------
# Main Prompt Functions
# ----------------------------------------------------------------------------

# fish_prompt - Left side of the prompt
#
# Displays: [environment][pwd]
#
# Structure:
#   1. Environment segment (if conda or venv active)
#      - Yellow background for conda
#      - Pale white background for venv
#   2. PWD segment (blue background)
#   3. Trailing space for command input
#
# Also captures $status and $CMD_DURATION for use by fish_right_prompt.
#
function fish_prompt
    # Capture status immediately (before any commands run)
    set -g __stellars_last_status $status
    set -g __stellars_last_duration $CMD_DURATION

    set -l env_info (__stellars_env)
    set -l pwd_str (__stellars_pwd)
    set -l sep (printf '\ue0b0')
    set -l prompt ''

    # Add newline before prompt (visual separation between commands)
    # Skip on first prompt of the session (MOTD/gpustat provides spacing)
    if set -q __stellars_prompt_shown
        set prompt $prompt\n
    else
        set -g __stellars_prompt_shown 1
    end

    # Environment segment (conda or venv)
    if test -n "$env_info"
        set -l env_type (string split ':' -- $env_info)[1]
        set -l env_name (string split ':' -- $env_info)[2]
        
        # Select background color based on environment type
        set -l bg $stellars_prompt_env_bg_conda
        if test "$env_type" = "venv"
            set bg $stellars_prompt_env_bg_venv
        end
        
        # Render: [bg color][text] env_name [next bg][current bg as fg]chevron
        set prompt $prompt(set_color -b $bg)(set_color $stellars_prompt_env_fg)" $env_name "(set_color -b $stellars_prompt_pwd_bg)(set_color $bg)$sep
    end

    # PWD segment
    set prompt $prompt(set_color -b $stellars_prompt_pwd_bg)(set_color -o $stellars_prompt_pwd_fg)" $pwd_str "(set_color normal)(set_color $stellars_prompt_pwd_bg)$sep

    # Reset colors and add trailing space
    set prompt $prompt(set_color normal)" "
    echo -n $prompt
end

# fish_right_prompt - Right side of the prompt
#
# Displays: [git][error] [duration]
#
# Visual patterns:
#   < git |                    - git only
#   < git < error |            - git + error connected
#   < git < < time |           - git, chevron-out, space, time
#   < git < error < < time |   - git + error connected, chevron-out, space, time
#
# Legend: < = left chevron (cut-in), | = square end
#
function fish_right_prompt
    set -l git_info (__stellars_git_info)
    set -l sep_left (printf '\ue0b2')
    set -l result ''
    set -l last_bg ''
    
    # Pre-calculate what segments will be shown
    set -l has_error 0
    set -l has_duration 0
    if test "$__stellars_last_status" -ne 0 2>/dev/null
        set has_error 1
    end
    if test -n "$__stellars_last_duration"
        if test $__stellars_last_duration -ge $stellars_prompt_duration_threshold
            set has_duration 1
        end
    end
    
    # Git segment (first on right)
    if test -n "$git_info"
        set -l is_dirty (string split ':' -- $git_info)[1]
        set -l git_text (string split ':' -- $git_info)[2]
        
        # Select background color based on dirty status
        set -l bg $stellars_prompt_git_bg_clean
        if test "$is_dirty" = "1"
            set bg $stellars_prompt_git_bg_dirty
        end
        
        # Left chevron (cut-in) + content
        set result $result(set_color $bg)$sep_left(set_color -b $bg)(set_color $stellars_prompt_git_fg)" $git_text "
        set last_bg $bg
    end
    
    # Error segment (if last command failed) - connected to git
    if test $has_error -eq 1
        # Left chevron cutting into previous segment
        if test -n "$last_bg"
            set result $result(set_color -b $last_bg)(set_color $stellars_prompt_error_bg)$sep_left
        else
            set result $result(set_color $stellars_prompt_error_bg)$sep_left
        end
        set result $result(set_color -b $stellars_prompt_error_bg)(set_color $stellars_prompt_error_fg)" $__stellars_last_status "
        set last_bg $stellars_prompt_error_bg
    end
    
    # Duration segment (if command exceeded threshold)
    if test $has_duration -eq 1
        set -l duration_str (__stellars_duration)
        if test -n "$duration_str"
            # Square butt + space before duration
            if test -n "$last_bg"
                set result $result(set_color normal)" "
            end
            # Left chevron (cut-in) + content
            set result $result(set_color $stellars_prompt_duration_bg)$sep_left(set_color -b $stellars_prompt_duration_bg)(set_color $stellars_prompt_duration_fg)" $duration_str "
            set last_bg $stellars_prompt_duration_bg
        end
    end
    
    if test -n "$result"
        echo -n $result(set_color normal)
    end
end
