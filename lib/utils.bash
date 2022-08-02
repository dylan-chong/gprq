function log() {
    echo "$*" >> $HOME/Desktop/log
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
    if command -v python3 &> /dev/null; then
        /usr/bin/env python3 "$@"
    else
        /usr/bin/env python "$@"
    fi
}

function paste_from_clipboard() {
    if command -v pbpaste &> /dev/null; then
        pbpaste
    elif command -v pbpaste &> /dev/null; then
        xclip -selection clipboard -o
    else
        exit_with_message 'Clipboard not supported. Please pass a commit message instead'
    fi
}

function exit_with_message {
    printf '%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

# Not all functions are using this yet. TODO use this, but also options for
# different formatting
function run_with_header() {
    local command="$@"
    echo "------------------------------- > $command ------------------------------"
    echo
    $command
    echo
}
