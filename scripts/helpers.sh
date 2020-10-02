#!/bin/bash -

##
# Varialbes
##
DOWNLOAD_FILE="/tmp/tmux_net_speed.download"
UPLOAD_FILE="/tmp/tmux_net_speed.upload"

get_tmux_option() {
    local option=$1
    local default_value=$2
    local option_value="$(tmux show-option -gqv "$option")"

    if [[ -z "$option_value" ]]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

set_tmux_option() {
    local option=$1
    local value=$2
    tmux set-option -gq "$option" "$value"
}

get_velocity()
{
    local new_value=$1
    local old_value=$2

    # Consts
    local THOUSAND=1024
    local MILLION=1048576

    local interval=$(get_tmux_option 'status-interval' 5)
    local vel=$(( ( new_value - old_value ) / interval ))
    local vel_kb=$(( vel / THOUSAND ))
    local vel_mb=$(( vel / MILLION ))

    if [[ $vel_mb != 0 ]] ; then
        echo -n "$vel_mb MB/s"
    elif [[ $vel_kb != 0 ]] ; then
        echo -n "$vel_kb KB/s";
    else
        echo -n "$vel B/s";
    fi
}

# Reads from value from file. If file does not exist,
# is empty, or not readable, starts back at 0
read_file()
{
    local path="$1"
    local fallback_val=0

    # File exists and is readdable?
    if [[ ! -f "$path" ]] ; then
        echo $fallback_val
        return 1
    elif [[ ! -r "$path" ]]; then
        echo $fallback_val
        return 1
    fi

    # Does the file have content?
    tmp=$(< "$path")
    if [[ "x${tmp}" == "x" ]] ; then
        echo $fallback_val
        return 1
    fi

    # Now return known value
    echo $tmp
}

# Update values in file
write_file()
{
    local path="$1"
    local val="$2"

    # TODO Add error checking
    echo "$val" > "$path" 2>&1
}

get_interfaces(){
    # local interfaces=$(get_tmux_option @net_speed_interfaces "")
    local interfaces=""
    if [[ -z "$interfaces" ]] ; then
        if is_osx; then
	  # only list en-prefix interfaces
	  local interfaces=$(netstat -i -b | awk -F " " '{print $1}' | tail -n+2 | awk '!seen[$1]++' | awk '{print $1}' | sed 's/*//' | sed '/^e/!d')
	  # netstat -I en0 -b | sed '1,1d' | head -n 1 | awk -F " " '{print $7}'
	elif is_linux; then
	  for interface in /sys/class/net/*; do
	      interfaces+=$(echo $(basename $interface) " ");
	  done
	elif is_cygwin; then
	  # panic here
	  echo "NOT SUPPORTED"
	fi
    fi

    # Do not quote the variable. This way will handle trailing whitespace
    echo -n $interfaces
}

sum_speed()
{
    local column=$1
    declare -a interfaces=$(get_interfaces)

    local line=""
    local val=0
    for intf in ${interfaces[@]} ; do
        if is_linux; then
	  line=$(cat /proc/net/dev | grep "$intf" | cut -d':' -f 2)
	  speed="$(echo -n $line | cut -d' ' -f $column)"
	  let val+=${speed:=0}
	fi
	if is_osx;then
	  # echo $intf
	  line=$(netstat -I $intf -b| awk -v column=$column -F " " '{print $(column)}'  | tail -n+2  |  awk '!seen[$1]++' | sed '/^0/d' )
	  let val+=${line:=0}
	fi
    done

    echo $val
}

is_osx() {
    [[ $(uname -s) =~ Darwin* ]]
}

is_linux() {
    [[ $(uname -s) =~ Linux* ]]
}

is_cygwin() {
    [[ $(uname -s) =~ CYGWIN* ]]
}

command_exists() {
    local command="$1"
    type "$command" >/dev/null 2>&1
}
