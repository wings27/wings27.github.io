#!/bin/bash

set -e # Exit with nonzero exit code if anything fails

SOURCE_BRANCH="master"
TARGET_BRANCH="master"

function doCompile {
  chmod +x ./compile.sh
  ./compile.sh
}

git --version

# Skipping deploy on pull requests and commits on other branches.
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo;
    echo "Warning: This build won't be deployed. Now building..."
    echo;
    doCompile
    exit 0
fi

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=https://${GH_TOKEN}${REPO/https:\/\/github.com/@github.com}
SHA=`git rev-parse --verify HEAD`

git config remote.origin.fetch refs/heads/*:refs/remotes/origin/*
git fetch --all

git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH

# Run our compile script
doCompile

git add --all
echo;

echo "git status:"
git status --short

if git diff --cached --quiet; then
    git status
	echo "No changes detected. Exiting..."
	exit 0
fi

# Git add & commit
git config --global user.name "Travis CI"
git config --global user.email "$COMMIT_AUTHOR_EMAIL"
echo;

git commit -m "CI Commit: Based on ${SHA}"

echo;
echo "git log:"
git log -n 10 --graph --pretty=oneline --abbrev-commit --decorate --date=relative
echo;

# All set up. Push to remote.
git push --verbose $SSH_REPO $TARGET_BRANCH
