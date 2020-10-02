#!/bin/bash -

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/helpers.sh"

sum_download_speed()
{
    # Output uses first column
    if is_osx;then
      sum_speed 7
    elif is_linux;then
      sum_speed 1
    fi
}

main()
{
    local file=$DOWNLOAD_FILE
    local old_val=$(read_file $file)
    local new_val=$(sum_download_speed)

    write_file $file $new_val
    local vel=$(get_velocity $new_val $old_val)

    ## Format output
    local format=$(get_tmux_option @download_speed_format "%s")
    local down_load_spped=$(printf "$format" "$vel")
    echo "$down_load_spped"
}
main

