# Stellars JupyterLab DS Fish Prompt
# Standalone prompt with chevron style - no Tide dependency
#
# Features:
# - Environment display (conda/venv) with color differentiation
# - PWD with DIRTRIM-style abbreviation
# - Git branch on right
# - Powerline/chevron separators
#
# Usage: source this file in config.fish or copy functions to separate files

# Configuration (override these as needed)
set -q stellars_prompt_dirtrim || set -g stellars_prompt_dirtrim 3
set -q stellars_prompt_env_bg_conda || set -g stellars_prompt_env_bg_conda FFD966
set -q stellars_prompt_env_bg_venv || set -g stellars_prompt_env_bg_venv E8E8E8
set -q stellars_prompt_env_fg || set -g stellars_prompt_env_fg 000000
set -q stellars_prompt_pwd_bg || set -g stellars_prompt_pwd_bg 2266AA
set -q stellars_prompt_pwd_fg || set -g stellars_prompt_pwd_fg E0E0E0
set -q stellars_prompt_git_bg || set -g stellars_prompt_git_bg 228B22
set -q stellars_prompt_git_fg || set -g stellars_prompt_git_fg 000000
set -q stellars_prompt_char || set -g stellars_prompt_char '❯'
set -q stellars_prompt_char_color || set -g stellars_prompt_char_color 5FD700
set -q stellars_prompt_char_error || set -g stellars_prompt_char_error FF0000

# Helper: convert hex color to set_color argument
function __stellars_color -a hex
    echo $hex
end

# Get abbreviated PWD (DIRTRIM style)
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

# Get environment name (venv takes priority over conda)
function __stellars_env
    if set -q VIRTUAL_ENV
        # Look up friendly name from nb_venv_kernels
        set -l venv_path (string replace "/home/lab/workspace/" "" -- $VIRTUAL_ENV)
        set -l venv_name (nb_venv_kernels list --json 2>/dev/null | jq -r --arg path "$venv_path" '.environments[] | select(.path == $path) | .name' 2>/dev/null)

        # Fallback: use parent directory of .venv
        if test -z "$venv_name"
            set venv_name (basename (dirname $VIRTUAL_ENV))
        end

        echo "venv:$venv_name"
    else if set -q CONDA_DEFAULT_ENV
        echo "conda:$CONDA_DEFAULT_ENV"
    end
end

# Get git branch
function __stellars_git_branch
    set -l branch (git branch --show-current 2>/dev/null)
    if test -n "$branch"
        echo $branch
    end
end

# Main prompt function
function fish_prompt
    set -l last_status $status

    # Get components
    set -l env_info (__stellars_env)
    set -l pwd_str (__stellars_pwd)

    # Chevron separator
    set -l sep ''

    # Start building prompt
    set -l prompt ''

    # Environment segment
    if test -n "$env_info"
        set -l env_type (string split ':' -- $env_info)[1]
        set -l env_name (string split ':' -- $env_info)[2]

        if test "$env_type" = "venv"
            set -l bg $stellars_prompt_env_bg_venv
        else
            set -l bg $stellars_prompt_env_bg_conda
        end

        set prompt $prompt(set_color -b $bg)(set_color $stellars_prompt_env_fg)" $env_name "(set_color -b $stellars_prompt_pwd_bg)(set_color $bg)$sep
    end

    # PWD segment
    if test -n "$env_info"
        set prompt $prompt(set_color -b $stellars_prompt_pwd_bg)(set_color $stellars_prompt_pwd_fg)" $pwd_str "(set_color normal)(set_color $stellars_prompt_pwd_bg)$sep
    else
        set prompt $prompt(set_color -b $stellars_prompt_pwd_bg)(set_color $stellars_prompt_pwd_fg)" $pwd_str "(set_color normal)(set_color $stellars_prompt_pwd_bg)$sep
    end

    # Reset and newline
    set prompt $prompt(set_color normal)

    # Character on new line
    if test $last_status -eq 0
        set prompt $prompt\n(set_color $stellars_prompt_char_color)$stellars_prompt_char(set_color normal)" "
    else
        set prompt $prompt\n(set_color $stellars_prompt_char_error)$stellars_prompt_char(set_color normal)" "
    end

    echo -n $prompt
end

# Right prompt with git branch
function fish_right_prompt
    set -l branch (__stellars_git_branch)

    if test -n "$branch"
        set -l sep ''
        echo -n (set_color $stellars_prompt_git_bg)$sep(set_color -b $stellars_prompt_git_bg)(set_color $stellars_prompt_git_fg)" $branch "(set_color normal)
    end
end
