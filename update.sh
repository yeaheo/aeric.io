#!/bin/bash
# Description: update my blog
# Author: Aeric Lve
# Date: 2019-01-11
# Email: <eric.lv@aeric.io>
# WebSite: https://aeric.io

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
msg="rebuilding site `date`"

if [ $# -eq 1 ]
  then msg="$1"
fi

# Push Hugo content
git add -A
git commit -m "$msg"
git push origin master

# Push Hugo Themes
cd themes
git add -A
git commit -m "$msg"
git push origin master
cd ..

# Build the project. 
hugo

# Go To Public folder
cd public

# Add changes to git.
git add -A

# Commit changes.
git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..

# 开启评论功能
#sed -i '7s/true/false/g' ./*
