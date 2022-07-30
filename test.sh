#!/usr/bin/env bash

set -eo pipefail
source ./lib/main.bash

failed_tests=0

function expect_to_equal() {
    local actual="$1"
    local expected="$2"
    local label="$3"

    if [ "$actual" != "$expected" ]; then
        echo "- Test failed: \`$label\`"
        actual_msg=`f -b "$actual"`
        expected_msg=`f -b "$expected"`
        echo "    - Expected ${actual_msg} to be ${expected_msg}"
        echo
        failed_tests=$((failed_tests+1))
    fi
}

function test() {
    local function_call_string="$1"
    local operator="$2"
    local expected="$3"

    if [ "$operator" != '==' ]; then
        echo "Invalid operator '$operator' for test '$*'"
        return
    fi

    log AAAAAAAAA: "$function_call_string"
    local result=`eval $function_call_string`

    expect_to_equal "$result" "$expected" "$function_call_string"
}

# ************************* Test: commit_message_to_branch *************************

test 'commit_message_to_branch "hello world"' \
    == "hello-world"
test 'commit_message_to_branch "hello world with lots of words"' \
    == "hello-world-with-lots-of-words"
test 'commit_message_to_branch "hello: world stuff"' \
    == "hello/world-stuff"
test 'commit_message_to_branch "Hello: World  stuff"' \
    == "hello/world-stuff"
test 'commit_message_to_branch "Hello: World__stuff"' \
    == "hello/world-stuff"
test 'commit_message_to_branch "Hello: world stuff"' \
    == "hello/world-stuff"
test 'commit_message_to_branch "Hello: world stuff - part 1 - fix things"' \
    == "hello/world-stuff--part-1--fix-things"
test 'commit_message_to_branch "Hello: world stuff with lots of words"' \
    == "hello/world-stuff-with-lots-of-words"
test 'commit_message_to_branch "JIRA-123: Hello world stuff"' \
    == "JIRA-123/hello-world-stuff"
test 'commit_message_to_branch "JIRA-123 Hello world stuff"' \
    == "JIRA-123/hello-world-stuff"
test 'commit_message_to_branch "JIRA-123     Hello world stuff"' \
    == "JIRA-123/hello-world-stuff" # Required for reformat_clipboard_to_commit_message to work
test 'commit_message_to_branch "Testing stuff: Hello world"' \
    == "testing-stuff/hello-world"

# ************************* Test: branch_to_commit_message *************************

test 'branch_to_commit_message "hello-world"' \
    == "Hello world"
test 'branch_to_commit_message "hello-world-with-lots-of-words"' \
    == "Hello world with lots of words"
test 'branch_to_commit_message "hello/world-stuff"' \
    == "hello: World stuff"
test 'branch_to_commit_message "hello/world-stuff--part-1--fix-things"' \
    == "hello: World stuff - part 1 - fix things"
test 'branch_to_commit_message "hello/world-stuff-with-lots-of-words"' \
    == "hello: World stuff with lots of words"
test 'branch_to_commit_message "JIRA-123/hello-world-stuff"' \
    == "JIRA-123: Hello world stuff"
test 'branch_to_commit_message "testing-stuff/hello-world"' \
    == "testing stuff: Hello world"

# ************************* Test: reformat_clipboard_to_commit_message *************************

test 'printf "hello world" | reformat_clipboard_to_commit_message' \
    == "hello world"
test 'printf "JIRA-123 Hello world stuff" | reformat_clipboard_to_commit_message' \
    == "JIRA-123 Hello world stuff"
test 'printf "JIRA-123      Hello world stuff" | reformat_clipboard_to_commit_message' \
    == "JIRA-123 Hello world stuff"
test 'printf "ARIJ-987654\n\n\nThis is a test ARIJ task\n" | reformat_clipboard_to_commit_message' \
    == "ARIJ-987654 This is a test ARIJ task"

echo

if [ "$failed_tests" == "0" ]; then
    echo All tests passed!
    exit 0
else
    f -b "${failed_tests} tests failed"
    echo `not_bold`
    exit 1
fi
