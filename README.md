# gprq

`gprq` "Git Pull Request Quick" -- commit, branch and create a PR in a single command!

Basically, run `gprq`, and you've magically:

1. created new a branch
1. committed
1. pushed the branch to `origin`
1. opened the URL to create a Pull Request in the browser.
    - (If the PR already exists, GitHub will redirect you to the existing PR)

It's great for doing lots of atomic PRs/commits (small PRs with a single
purpose, so they are easy for people to code review).

# Installation

## Bash

```
installation_dir=~ # Feel free to customise this
cd $installation_dir
git clone git@github.com:dylan-chong/gprq.git

printf "\n# Load the gprq function\nsource $installation_dir/gprq/gprq.bash\n\n" >> ~/.bashrc
source .bashrc
```

## ZSH

### ZPlug

Similar for other plugin managers

```zsh
zplug dylan-chong/gprq, from:github
```

### Oh My Zsh

1. In your `.zshrc`
```zsh
plugins=(
    ...
    gprq
)
```
1. `git clone https://github.com/dylan-chong/gprq ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/gprq`
1. Start a new zsh session

### No plugin manager

Use the method in the Bash section, but `s/bash/zsh` in the instructions

# Compatibility

Currently works only with MacOS (pasting from clipboard and opening the URL in the browser will only work on Mac).
Works with GitHub and Bitbucket.

PRs welcome!

# Usage

It gets even more convenient!
Start off by making your code changes.
Then

```
git add <stuff to commit>
```

Then do one of the following

1. Pass a branch name - `gprq <branch_name>`
    - branch_name can be something like:
        - `fix-the-thing`
        - `fix/the-thing`
        - `JIRA-123/fix-the-thing`
        - `JIRA-123/fix-the-thing--part-1--stuff`
    - The commit message will be a reformatted branch name

1. Pass a commit message - `gprq <commit_message>`
    - commit_message can be something like:
        - `Fix the thing`
        - `Fix: The thing`
        - `JIRA-123: Fix the thing`
        - `JIRA-123: Fix the thing - Part 1`
    - The branch name will be a reformatted commit message

1. Use branch/commit name of JIRA ticket - My favourite option!
    - Drag-select the `JIRA-123 Fix the thing from the
   website` from your JIRA ticket ![JIRA ticket](./docs/jira_screenshot.png)
        - Tip: It's easiest if drag-select from the right of the title up/left
    - Copy it to your clipboard
    - Run `gcmq`
    - Profit! (yea, lol, it works :shrug:)

# Tips

1. If you're using MacOS and you use multiple browsers, I highly recommend
   using [Browserosaurus](https://browserosaurus.com/) to select the browser
1. Never checkout the main/master branch. Always `git fetch && git checkout origin/HEAD`.
   That way you can never need to worry about pulling from the main branch.
   Even better, I like to alias this to `gcoh` "Git checkout (origin) head"
