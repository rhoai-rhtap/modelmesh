#!/bin/bash

#for i in $(gh pr list | awk '{print $1}');
#do
#    gh pr edit $i -t old
#    gh pr close $i -d
#done
#
#
#cp -r /home/dchouras/RHODS/DevOps/FBC/operator-back/* .
#git pull --no-edit
git add .
git status
git commit -m "trying ta"
git push
