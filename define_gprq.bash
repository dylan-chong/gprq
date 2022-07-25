gprq() {
    # Copied from https://stackoverflow.com/a/246128/1726450
    script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    "$script_dir/lib/run.bash" $@
}
