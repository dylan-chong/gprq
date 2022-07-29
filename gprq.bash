# To be `source`d so doesn't need a shebang line

# Defines the gprq function
# This file is needed for bash users

# Copied from https://stackoverflow.com/a/246128/1726450
export GPRQ_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

gprq() {
    cmd="\
        set -e \
        && source $GPRQ_DIR/lib/main.bash \
        && main \"$@\" \
        "

    bash -c "$cmd"
}
