# To be `source`d so doesn't need a shebang line

# Defines the gprq function
# This file needs to be .plugin.zsh oh-my-zsh, and .zsh for zplug and antigen

# Copied from https://stackoverflow.com/a/246128/1726450
export GPRQ_DIR=$( cd -- "$( dirname -- "$0" )" &> /dev/null && pwd )

gprq() {
    cmd="\
        set -eo pipefail \
        && source $GPRQ_DIR/lib/main.bash \
        && main \"$@\" \
        "

    bash -c "$cmd"
}
