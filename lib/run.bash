#!/usr/bin/env bash

function main() {
    user_confirm_status_or_add

    if [ -z "$1" ]; then
        # Take commit message from clipboard so you can copy the jira ticket number and description straight after it
        # MacOS specific
        local message=`trim_string "$(pbpaste)" | tr '\n' ' ' | perl -pe 's/\s+/ /g'`
        local branch=`commit_message_to_branch "$message"`
    else
        # Check if argument is branch name or commit message by if it has
        # no spaces and a / or _ or - in it
        if [[ "$*" =~ ^[A-Za-z0-9_-]+[/_-][A-Za-z0-9/_-]+$ ]]; then
            # Argument was branch name
            local branch=`trim_string "$1"`
            local message=`branch_to_commit_message "$branch"`
        else
            # Argument was commit message
            local message=`trim_string "$*"`
            local branch=`commit_message_to_branch "$message"`
        fi
    fi

    echo "    New Branch: `bold`$branch`not_bold`"
    echo "Commit message: `bold`$message`not_bold`"
    echo

    read -p "Look good? `bold`[y/n]`not_bold`? " CONT
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

function user_confirm_status_or_add() {
    while true; do
        echo
        echo '--------------------------------- > git status --------------------------------'
        echo
        git status
        echo
        echo -------------------------------------------------------------------------------
        echo

        echo "Are you on the `f -b 'right base commit'` *and* does this show the `f -b 'right staged files'`?"
        echo "  `f -b 'y'`es:         continue"
        echo "  `f -b 'a'`:           run 'git add -p'"
        echo "  `f -b 'af <file>'`:   run 'git add <filename>'"
        echo "  `f -b 'r'`:           run 'git reset -p'"
        echo "  `f -b 'd'`:           run 'git diff --staged'"
        echo "  `f -b 'F'`:           run 'git add -A' (you slimey bugger ;P)"
        echo "  `f -b 'n'`o:          cancel"
        echo
        read -p "`f -b '[y/n/a/af/r/d/F]'`? " CONT
        echo

        case "$CONT" in
            y)
                echo -------------------------------------------------------------------------------
                echo
                break;
                ;;
            a)
                echo `f -b '✨✨ I like you! ✨✨'`
                echo '--------------------------------- > git add -p --------------------------------'
                git add -p
                ;; # Loop to confirm
            r)
                echo '-------------------------------- > git reset -p -------------------------------'
                git reset -p
                ;; # Loop to confirm
            d)
                echo '----------------------------- > git diff --staged -----------------------------'
                git --paginate diff --staged
                ;; # Loop to confirm
            boo)
                echo 'Slimey bugger alert!'
                echo '> git add -A'
                git add -A
                ;; # Loop to confirm
            n|*)
                echo "Cancelling";
                exit
        esac
    done
}

function trim_string() {
    local string="$1"
    echo "$string" | trim_string_pipe
}

function trim_string_pipe() {
    perl -pe 's/^\s*//' | perl -pe 's/\s*$//'
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
    # If `open` exists. TODO do proper platform check
    if command -v open &> /dev/null; then
        open "$url"
    else
        echo "'open' could not be found. Open the PR yourself:"
        echo
        echo "    $url"
        echo
        exit
    fi
}

function current_branch() {
    git branch | awk '/^\* / { print $2 }'
}

# Takes commit message as first argument
# Input format: "[a prefix: ]a suffix"
# Input format: "[a-prefix/]a-suffix"
#
# TODO make an actual unit test suite
# function test() {
    # local result=`commit_message_to_branch "$1"`
    # if [ "$result" != "$2" ]; then
        # echo "- Expected '$result' to be '$2'"
    # fi
# }
#
# test "hello world" "hello-world"
# test "hello world with lots of words" "hello-world-with-lots-of-words"
# test "hello: world stuff" "hello/world-stuff"
# test "Hello: World  stuff" "hello/world-stuff"
# test "Hello: World__stuff" "hello/world-stuff"
# test "Hello: world stuff" "hello/world-stuff"
# test "Hello: world stuff - part 1 - fix things" "hello/world-stuff--part-1--fix-things"
# test "Hello: world stuff with lots of words" "hello/world-stuff-with-lots-of-words"
# test "JIRA-123: Hello world stuff" "JIRA-123/hello-world-stuff"
# test "Testing stuff: Hello world" "testing-stuff/hello-world"
function commit_message_to_branch() {
    local commit_message="$1"

    # If has prefix
    if [[ "$commit_message" =~ [A-Za-z0-9_-]:\ +[A-Za-z0-9_-] ]]; then
        local prefix=`echo "$commit_message" | perl -pe 's/:\s+.*//'`
        local commit_message_separator=`echo "$commit_message" | perl -pe 's/[^:]+(:\s+).*/\1/'`
        local suffix=${commit_message#"$prefix$commit_message_separator"}

        # If prefix is JIRA-123 (jira ticket)
        if [[ "$prefix" =~ ^[A-Z][A-Z]+-[123]+$ ]]; then
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
#
# function test() {
    # local result=`branch_to_commit_message "$1"`
    # if [ "$result" != "$2" ]; then
        # echo "- Expected '$result' to be '$2'"
    # fi
# }
# test "hello-world" "Hello world"
# test "hello-world-with-lots-of-words" "Hello world with lots of words"
# test "hello/world-stuff" "hello: World stuff"
# test "hello/world-stuff--part-1--fix-things" "hello: World stuff - part 1 - fix things"
# test "hello/world-stuff-with-lots-of-words" "hello: World stuff with lots of words"
# test "JIRA-123/hello-world-stuff" "JIRA-123: Hello world stuff"
# test "testing-stuff/hello-world" "testing stuff: Hello world"
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

# Format
function f() {
    if [ "$1" != "-b" ]; then
        echo "Only -b" is supported
    fi

    printf `bold`"${@: 2}"`not_bold`
}

function bold() {
    tput bold
}

function not_bold() {
    tput sgr0
}

main $@
