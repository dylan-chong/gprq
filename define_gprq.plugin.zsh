# Copied from https://stackoverflow.com/a/246128/1726450
GPRQ_DIR=$( cd -- "$( dirname -- "$0" )" &> /dev/null && pwd )

gprq() {
    "$GPRQ_DIR/lib/run.bash" $@
}