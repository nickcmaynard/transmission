#!/usr/bin/env bash
#===============================================================================
#          FILE: transmission.sh
#
#         USAGE: ./transmission.sh
#
#   DESCRIPTION: Entrypoint for transmission docker container
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 09/28/2014 12:11
#      REVISION: 1.0
#===============================================================================

set -o nounset                              # Treat unset variables as an error

dir="/var/lib/transmission-daemon"

### timezone: Set the timezone for the container
# Arguments:
#   timezone) for example EST5EDT
# Return: the correct zoneinfo file will be symlinked into place
timezone() { local timezone="${1:-EST5EDT}"
    [[ -e /usr/share/zoneinfo/$timezone ]] || {
        echo "ERROR: invalid timezone specified: $timezone" >&2
        return
    }

    if [[ $(cat /etc/timezone) != $timezone ]]; then
        echo "$timezone" > /etc/timezone
        ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1
    fi
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() { local RC=${1:-0}
    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container

The 'command' (if provided and valid) will be run instead of transmission
" >&2
    exit $RC
}

cd /tmp

while getopts ":ht:" opt; do
    case "$opt" in
        h) usage ;;
        t) timezone "$OPTARG" ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ "${TZ:-""}" ]] && timezone "$TZ"

[[ -d $dir/downloads ]] || mkdir -p $dir/downloads
[[ -d $dir/incomplete ]] || mkdir -p $dir/incomplete
[[ -d $dir/info/blocklists ]] || mkdir -p $dir/info/blocklists
chown -Rh nick. $dir

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
elif ps -ef | egrep -v 'grep|transmission.sh' | grep -q transmission; then
    echo "Service already running, please restart container to apply changes"
else
    exec su -l nick -s /bin/bash -c "exec transmission-daemon \
                --config-dir $dir/info \
                --foreground \
                --no-portmap --allowed \\* 2>&1"
fi
