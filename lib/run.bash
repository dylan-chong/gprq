#!/usr/bin/env bash

function main() {
    echo '> git status'
    git status
    echo

    read -p "Are you on the right base commit *and* does this show the right staged files [y/n]? " CONT
    echo

    if [ "$CONT" != "y" ]; then
        echo "Cancelling";
        return
    fi

    if [ -z "$1" ]; then
        # Take commit message from clipboard so you can copy the jira ticket number and description straight after it
        local message=`pbpaste | tr '\n' ' ' | perl -pe 's/\s+/ /g'`
        local branch=`commit_message_to_branch "$message"`
    else
        # Check if argument is branch name or commit message by if it has
        # no spaces and a / or _ or - in it
        if [[ "$@" =~ ^[A-Za-z0-9_-]+[/_-][A-Za-z0-9/_-]+$ ]]; then
            # Argument was branch name
            local branch="$1"
            local message=`branch_to_commit_message "$branch"`
        else
            # Argument was commit message
            local message=`echo "$@" | perl -pe 's/^\s*//' | perl -pe 's/\s*$//'`
            local branch=`commit_message_to_branch "$message"`
        fi
    fi

    echo "New Branch: $branch"
    echo "Commit message: $message"
    echo

    read -p "Are these correct [y/n]? " CONT
    echo

    if [ "$CONT" != "y" ]; then
        echo "Cancelling";
        return
    fi

    git checkout -b "$branch" \
        && git commit -m "$message" \
        && git push -u origin "$branch" \
        && open_pull_request_in_browser
}

function open_pull_request_in_browser() {
    # Goes to the URL for creating a new pull request in the browser. For
    # GitHub, the branch is selected automatically, and if the pull request
    # already exists for that branch, GitHub will redirect to the existing pull
    # request. For Bitbucket, the new pull request page is opened.
    local base=`git remote get-url origin | perl -pe 's/\.git$//' | perl -pe 's/git\@([^:]+):/https:\/\/\1\//'`
    if [[ $base == 'https://bitbucket.org'* ]]; then
        local url="$base/pull-requests/new"
    else
        local url="$base/pull/`current_branch`"
    fi

    # MacOS specific
    # TODO detect platform
    echo "Opening PR URL: $url"
    open "$url"
}

function current_branch() {
    git branch | awk '/^\* / { print $2 }'
}

function commit_message_to_branch() {
    # TODO refactor and fix bugs, SOLV
    local commit_message="$1"
    echo $commit_message \
        | perl -pe 's/(:|\/)//g' \
        | perl -pe 's/^(SOLV-\d+(?=:)?|[^:]+(?=:)):?\s*(.*\S)\s*$/\1\/\l\2/' \
        | perl -pe 's/[^\w\/]+/-/g' \
        | tr '[:upper:]' '[:lower:]' \
        | perl -pe 's/^solv/SOLV/'
}

# Takes branch as stdin
function branch_to_commit_message() {
    local branch="$1"

    # If contains a slash
    if [[ "$branch" =~ / ]]; then
        local prefix=`echo $branch | perl -pe 's/\/.*//'`
        local prefix_formatted="$prefix"
        local separator=': '
        local suffix=${branch#"$prefix"/}
    else
        local prefix_formatted=''
        local separator=''
        local suffix="$branch"
    fi

    # Pass branch suffix as argument and convert to commit messagee
    # 1. Replace all - and _ with spaces
    # 2. Replace 2+ spaces with ' - ' so you can use '--' in the branch name represent an actual dash
    local suffix_formatted=`echo "$suffix" | perl -pe 's/_|-/ /g' | perl -pe 's/\s\s+/ - /g'`

    echo "$prefix_formatted$separator$suffix_formatted"
}

main $@
