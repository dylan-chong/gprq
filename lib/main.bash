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
        if [[ "$*" =~ ^[A-Za-z0-9_-]+[/_-][A-Za-z0-9/_\.-]+$ ]]; then
            # Argument was branch name
            local branch=`trim_string "$1"`
            local message=`branch_to_commit_message "$branch"`
        else
            # Argument was commit message
            local message=`trim_string "$*"`
            local branch=`commit_message_to_branch "$message"`
        fi
    fi

    tmpfile=$(mktemp /tmp/variables.XXXXXX)
    echo "branch: $branch" > "$tmpfile"
    echo "message: $message" >> "$tmpfile"

    ${EDITOR:-nano} "$tmpfile"

    # Load the new values from the file
    while IFS=: read -r name value; do
      if [ "$name" = "branch" ]; then
        edited_branch=$(echo "$value" | xargs)
      elif [ "$name" = "message" ]; then
        edited_message=$(echo "$value" | xargs)
      fi
    done < "$tmpfile"
    rm "$tmpfile"

    if [ "$CONT" != "y" ]; then
        echo "Cancelling";
        exit
    fi

    if git show-ref -q --heads "$branch"; then
        exit_with_message "Error: Branch '$edited_branch' already exists";
    fi

    # Detach so we can commit without polluting the current branch.
    #
    # We've already checked that the branch doesn't exist so it shouldn't ever
    # fail (TM). We should commit before creating the branch, as it's more
    # likely to fail for whatever reason. e.g., if test/lint runs and fails
    # before commit.
    : \
        && echo "> git checkout --detach" \
        && git checkout --detach \
        && echo "> git commit -m \"$edited_branch\"" \
        && git commit -m "$edited_message" \
        && echo "> git checkout -b \"$edited_branch\"" \
        && git checkout -b "$edited_branch" \
        && echo "> git push -u origin \"$edited_branch\"" \
        && push_output=$(git push -u origin "$edited_branch" 2>&1) \
        && echo "$push_output" \
        && extract_and_open_pull_request "$push_output"
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
        echo "  `f -b 'F'`:           run 'git add -A' (sneaky ;P)"
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

function extract_and_open_pull_request() {
    local push_output="$1"
    
    # Extract pull request URL from git push output
    # Try different patterns that various git hosting services might use
    
    # GitHub pattern: "Create a pull request for 'branch' on GitHub by visiting:"
    local url=$(echo "$push_output" | grep -A1 "Create a pull request.*by visiting:" | grep -o 'https://[^[:space:]]*' | head -1)
    
    # If not found, try other common patterns
    if [ -z "$url" ]; then
        # GitLab pattern: "Create a merge request for 'branch' by visiting:"
        url=$(echo "$push_output" | grep -A1 "Create a merge request.*by visiting:" | grep -o 'https://[^[:space:]]*' | head -1)
    fi
    
    if [ -z "$url" ]; then
        # Bitbucket pattern: "Create a pull request for 'branch' by visiting:"
        url=$(echo "$push_output" | grep -A1 "Create a pull request.*by visiting:" | grep -o 'https://[^[:space:]]*' | head -1)
    fi
    
    if [ -z "$url" ]; then
        # Generic pattern: look for any URL after "by visiting:"
        url=$(echo "$push_output" | grep -A1 "by visiting:" | grep -o 'https://[^[:space:]]*' | head -1)
    fi
    
    if [ -n "$url" ]; then
        echo "> python -m webbrowser -t \"$url\""
        exec_python -m webbrowser -t "$url"
        return
    fi
    
    echo "Could not extract pull request URL from git push output, falling back to generated URL"
}
