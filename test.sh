#!/usr/bin/env bash

set -e
source ./lib/functions.bash

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
    local fn="$1"
    local fn_arg="$2"
    local operator="$3"
    local expected="$4"

    if [ "$operator" != '==' ]; then
        echo "Invalid operator '$operator' for test '$@'"
        return
    fi

    local result=`$1 "$fn_arg"`

    expect_to_equal "$result" "$expected" "$fn \"$fn_arg\""
}

test commit_message_to_branch "hello world" == "hello-world"
test commit_message_to_branch "hello world with lots of words" == "hello-world-with-lots-of-words"
test commit_message_to_branch "hello: world stuff" == "hello/world-stuff"
test commit_message_to_branch "Hello: World  stuff" == "hello/world-stuff"
test commit_message_to_branch "Hello: World__stuff" == "hello/world-stuff"
test commit_message_to_branch "Hello: world stuff" == "hello/world-stuff"
test commit_message_to_branch "Hello: world stuff - part 1 - fix things" == "hello/world-stuff--part-1--fix-things"
test commit_message_to_branch "Hello: world stuff with lots of words" == "hello/world-stuff-with-lots-of-words"
test commit_message_to_branch "JIRA-123: Hello world stuff" == "JIRA-123/hello-world-stuff"
test commit_message_to_branch "JIRA-123 Hello world stuff" == "JIRA-123/hello-world-stuff"
test commit_message_to_branch "JIRA-123     Hello world stuff" == "JIRA-123/hello-world-stuff"
test commit_message_to_branch "Testing stuff: Hello world" == "testing-stuff/hello-world"


test branch_to_commit_message "hello-world" == "Hello world"
test branch_to_commit_message "hello-world-with-lots-of-words" == "Hello world with lots of words"
test branch_to_commit_message "hello/world-stuff" == "hello: World stuff"
test branch_to_commit_message "hello/world-stuff--part-1--fix-things" == "hello: World stuff - part 1 - fix things"
test branch_to_commit_message "hello/world-stuff-with-lots-of-words" == "hello: World stuff with lots of words"
test branch_to_commit_message "JIRA-123/hello-world-stuff" == "JIRA-123: Hello world stuff"
test branch_to_commit_message "testing-stuff/hello-world" == "testing stuff: Hello world"

echo

if [ "$failed_tests" == "0" ]; then
    echo All tests passed!
    exit 0
else
    f -b "${failed_tests} tests failed"
    echo `not_bold`
    exit 1
fi
