# Defines the gprq function
# This file is needed for oh-my-zsh

# Copied from https://stackoverflow.com/a/246128/1726450
GPRQ_DIR=$( cd -- "$( dirname -- "$0" )" &> /dev/null && pwd )

gprq() {
    cmd="\
        set -e \
        && source $GPRQ_DIR/lib/functions.bash \
        && main $@ \
        "

    bash -c "$cmd"
}
