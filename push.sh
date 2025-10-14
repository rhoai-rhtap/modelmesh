#!/bin/bash
git add .
git status
branch=$(git branch --show-current)
epoch=$(date +%s)
git commit -m "adding changes to ${branch} branch at ${epoch}"