source "$GPRQ_DIR/lib/utils.bash"
source "$GPRQ_DIR/lib/input_formatters.bash"

function main() {
    user_confirm_status_or_add

    if [ -z "$1" ]; then
        # Take commit message from clipboard so you can copy the jira ticket number and description straight after it
        # MacOS specific
        local message=`paste_from_clipboard | reformat_clipboard_to_commit_message`
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
    echo -------------------------------------------------------------------------------
    echo

    if [ "$CONT" != "y" ]; then
        echo "Cancelling";
        exit
    fi

    if git show-ref -q --heads "$branch"; then
        exit_with_message "Error: Branch '$branch' already exists";
    fi

    # Detach so we can commit without polluting the current branch.
    #
    # We've already checked that the branch doesn't exist, so we should commit
    # before creating the branch, as it's more likely to fail for whatever
    # reason.

    : \
        && echo "> git checkout --detach" \
        && git checkout --detach \
        && echo "> git commit -m <message>" \
        && git commit -m "$message" \
        && echo "> git checkout -b <branch>" \
        && git checkout -b "$branch" \
        && echo "> git push -u origin <branch>" \
        && git push -u origin "$branch" \
        && echo "> git push -u origin <branch>" \
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
        echo "  `f -b 'n'`o:          cancel"
        echo "  `f -b 'ap'`:          run 'git add -p'"
        echo "  `f -b 'a'` <path>:    run 'git add <path>'"
        echo "  `f -b 'rp'`:          run 'git reset -p'"
        echo "  `f -b 'r'` <path>:    run 'git reset <path>'"
        echo "  `f -b 'd'`:           run 'git diff'"
        echo "  `f -b 'D'`:           run 'git diff --staged'"
        echo "  `f -b 'F'`:           run 'git add -A' (you slimey bugger ;P)"
        echo
        read -p "`f -b '[y/n/a/ap/r/rp/d/F]'`? " CONT
        echo

        case "$CONT" in
            y)
                echo -------------------------------------------------------------------------------
                echo
                break;
                ;;
            ap)
                echo '✨✨✨✨'
                echo '--------------------------------- > git add -p --------------------------------'
                git add -p
                ;; # Loop to confirm or add more files
            a\ *)
                local path=`echo $CONT | perl -pe 's/^a\s+//'`
                if [ "$path" == "." ]; then
                    echo "Sneaky!"
                fi
                echo "------------------ > git add ${path} -----------------"
                git add "$path"
                ;; # Loop to confirm or add more files
            rp)
                echo '------------------------------- > git reset -p --------------------------------'
                git reset -p
                ;; # Loop to confirm or add more files
            r\ *)
                local path=`echo $CONT | perl -pe 's/^r\s+//'`
                echo "----------------- > git reset ${path} ----------------"
                git reset "$path"
                ;; # Loop to confirm or add more files
            d)
                echo '--------------------------------- > git diff ----------------------------------'
                git --paginate diff
                ;; # Loop to confirm or add more files
            D)
                echo '----------------------------- > git diff --staged -----------------------------'
                git --paginate diff --staged
                ;; # Loop to confirm or add more files
            F) # to pay respects
                echo '> git add -A'
                git add -A
                ;; # Loop to confirm
            n|exit)
                echo "Cancelling";
                exit
                ;;
            *)
                f -b "Huh? I didn't understand \`$CONT\`"
                echo
                ;; # Loop
        esac
    done
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

    # https://docs.python.org/3/library/webbrowser.html
    exec_python -m webbrowser -t "$url"
}
