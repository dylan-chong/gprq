# Takes commit message as first argument
# Input format: "[a prefix: ]a suffix"
# Input format: "[a-prefix/]a-suffix"
function commit_message_to_branch() {
    local commit_message="$1"

    # If has JIRA prefix without the colon. Prefix must be uppercase
    if [[ "$commit_message" =~ ^[A-Z][A-Z]+-[0-9]+\ + ]]; then
        # Insert colon after JIRA prefix
        local commit_message_with_colon=`echo $commit_message | perl -pe 's/(^[A-Z][A-Z]+-[0-9]+)\s+/\1: /'`
        commit_message_to_branch "$commit_message_with_colon"
        return
    fi

    # If has prefix
    if [[ "$commit_message" =~ : ]]; then
        local prefix=`echo "$commit_message" | perl -pe 's/:.*//'`
        local commit_message_separator=`echo "$commit_message" | perl -pe 's/[^:]+(:\s+).*/\1/'`
        local suffix=${commit_message#"$prefix$commit_message_separator"}

        # If prefix is JIRA-123 (jira ticket)
        if [[ "$prefix" =~ ^[A-Z][A-Z]+-[0-9]+ ]]; then
            local prefix_formatted="$prefix"
        else
            # 1. Lowercase
            # 2. Trim
            # 3. Replace multiple spaces with a single "-"
            local prefix_formatted=`echo "$prefix" | perl -pe 's/([A-Z])/\L\1/g' | trim_string_pipe | perl -pe 's/\s+/-/g'`
        fi

        local separator='/' # branch separator
    else
        local prefix_formatted=''
        local separator=''
        local suffix=`echo "$commit_message" | perl -pe 's/([A-Z])/\L\1/g'`
    fi

    # 1. Lowercase
    # 2. Trim
    # 3. Replace space with -
    # 4. Replace multiple dashes with "--"
    local suffix_formatted=`echo $suffix | perl -pe 's/([A-Z])/\L\1/g' | trim_string_pipe | perl -pe 's/(\s|_)+/-/g' | perl -pe 's/--+/--/g'`

    echo "$prefix_formatted$separator$suffix_formatted"
}

# Takes branch as first argument
# Input format: "[a-prefix/]a-suffix"
# Output format: "[a prefix: ]a suffix"
function branch_to_commit_message() {
    local branch="$1"

    # If has prefix
    if [[ "$branch" =~ / ]]; then
        local prefix=`echo $branch | perl -pe 's/\/.*//'`
        local separator=': '
        local suffix=${branch#"$prefix"/}

        # If prefix is JIRA-123 (jira ticket)
        if [[ "$prefix" =~ ^[A-Z][A-Z]+-[123]+$ ]]; then
            local prefix_formatted="$prefix"
        else
            local prefix_formatted=`echo $prefix | perl -pe 's/_|-/ /g'`
        fi
    else
        local prefix_formatted=''
        local separator=''
        local suffix="$branch"
    fi

    # 1. Replace all - and _ with spaces
    # 2. Replace 2+ spaces with ' - ' so you can use '--' in the branch name represent an actual dash
    # 3. Capitalise first letter
    local suffix_formatted=`echo "$suffix" | perl -pe 's/_|-/ /g' | perl -pe 's/\s\s+/ - /g' | perl -pe 's/^(\w)/\U\1/'`

    echo "$prefix_formatted$separator$suffix_formatted"
}

# Input is stdin
function reformat_clipboard_to_commit_message() {
    tr '\n' ' ' \
        | perl -pe 's/\s+/ /g' \
        | trim_string_pipe
}
