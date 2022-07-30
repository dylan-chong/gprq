function log() {
    echo "$*" >> ~/Desktop/log
}

function trim_string() {
    local string="$1"
    echo "$string" | trim_string_pipe
}

function trim_string_pipe() {
    perl -pe 's/^\s*//' | perl -pe 's/\s*$//'
}

function current_branch() {
    git branch | awk '/^\* / { print $2 }'
}

# Format
function f() {
    if [ "$1" != "-b" ]; then
        echo "Only -b" is supported
    fi

    printf "`bold`${@: 2}`not_bold`"
}

function bold() {
    tput bold
}

function not_bold() {
    tput sgr0
}

function exec_python() {
    if command -v python &> /dev/null; then
        /usr/bin/env python3 "$@"
    else
        /usr/bin/env python "$@"
    fi
}
