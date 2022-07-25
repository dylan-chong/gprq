# gprq

`gprq` "Git Pull Request Quick" is a command to quickly and conveniently:

1. create new a branch
1. commit (generated from the branch name)
1. push the branch to `origin` (with the remote tracking setup)
1. open the URL to create a Pull Request in the browser. If the PR already
   exists, GitHub will redirect you to the existing PR

It's great for doing lots of atomic PRs/commits (small PRs with a single
purpose, so they are easy for people to code review).

## Usage

It gets even more convenient!
Start off by making your code changes.
Then

```
git add <stuff to commit>
```

Then do one of the following

1. `gprq <branch_name>` - branch_name can be something like:
    - `fix-the-thing`
    - `fix/the-thing`
    - `JIRA-123/fix-the-thing`
    - or even `JIRA-123/fix-the-thing--part-1--stuff`
    - The commit message will be a reformatted branch name

1. `gprq <commit_message>` - commit_message can be something like:
    - `Fix the thing`
    - `Fix: The thing`
    - `JIRA-123: Fix the thing`
    - The branch name will be a reformatted commit message

1. `gprq` - but before running it, copy `JIRA-123 Fix the thing from the
   website`

 <!-- # TODO finish this -->

## Compatibility

Currently works only with Mac (the only \*nix platform-specific bit is the opening the URL in the browser).
Works with GitHub and Bitbucket.

PRs welcome!

## Installation

### Bash

```
installation_dir=~ # Feel free to customise this
cd $installation_dir
git clone git@github.com:dylan-chong/gprq.git

echo "source $installation_dir/gprq.bash" >> ~/.bashrc
```

### ZSH

Use a plugin manager, e.g. Zplug:

```zsh
zplug dylan-chong/gprq, from:github
```
