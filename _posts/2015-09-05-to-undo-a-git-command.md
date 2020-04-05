---
layout:     post
title:      To Undo a Git Command
subtitle:   "-- The cheat sheet"
date:       2015-09-05 11:26
author:     wings27
header-img: "img/tag-git.jpg"
tags:
    - Git
---

It seems that I'm not alone to believe that git commands are poorly designed.[^1]

To make things worse, they also provide a human-unreadable documentation as well.[^2]
So it's very common for beginners to leave a mess in the workspace after running a God-knows-what-it-means git command. Therefore I wrote this blog. Hopefully this could save you from clueless.

## Table of Contents
{:.no_toc}

- toc
{:toc}


## The Cheat Sheet

Some commonly used git commands are listed below, along with the corresponding commands to undo or fixup the mess.

|   **Git Command**   |           **How To Undo**           |
|---------------------|-------------------------------------|
| `git add <file>...` | `git rm --cached <file>...`         |
| `git commit`        | `git reset HEAD^ --soft`            |
| `git commit`        | `git revert <commit_sha>`           |
| `git merge`         | `git reset --hard ORIG_HEAD`        |
| `git pull`          | `git reset HEAD@{1}`                |
| `git push`          | `git push --force origin <refspec>` |

## Reference

[^1]: [What I Hate About Git \| Hacker News](https://news.ycombinator.com/item?id=4340595)
[^2]: [10 things I hate about Git](http://stevebennett.me/2012/02/24/10-things-i-hate-about-git/)
[^3]: [How to remove the first commit in git?](http://stackoverflow.com/a/10911506/1294704)
