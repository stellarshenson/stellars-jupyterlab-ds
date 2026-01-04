# Fish completion for lab-utils
# Provides autocompletion for lab-utils commands and available scripts
# Supports both top-level and nested scripts (parent/child format)

# Helper function to collect scripts from a directory
function __lab_utils_scripts
    set -l global_dir /opt/utils/lab-utils.d
    set -l local_dir ~/.local/lab-utils.d

    for dir in $global_dir $local_dir
        if test -d $dir
            for script in $dir/*
                # Skip if not a file or not executable
                test -f $script -a -x $script; or continue

                # Skip README files
                set -l basename (basename $script)
                string match -q 'README*' $basename; and continue

                # Get name without extension
                set -l name (string replace -r '\.[^.]+$' '' $basename)
                echo $name

                # Check for corresponding .d subdirectory with nested scripts
                set -l subdir "$dir/$name.d"
                if test -d $subdir
                    for child_script in $subdir/*
                        test -f $child_script -a -x $child_script; or continue
                        set -l child_basename (basename $child_script)
                        string match -q 'README*' $child_basename; and continue
                        set -l child_name (string replace -r '\.[^.]+$' '' $child_basename)
                        echo "$name/$child_name"
                    end
                end
            end
        end
    end
end

# Disable file completion by default
complete -c lab-utils -f

# Options
complete -c lab-utils -n "__fish_is_first_arg" -s h -l help -d "Show help message"
complete -c lab-utils -n "__fish_is_first_arg" -s l -l list -d "List available scripts"
complete -c lab-utils -n "__fish_is_first_arg" -l create-local -d "Create local scripts directory"

# Script names (dynamically generated)
complete -c lab-utils -n "__fish_is_first_arg" -a "(__lab_utils_scripts)" -d "Script"

# EOF
