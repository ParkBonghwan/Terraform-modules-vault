#!/bin/bash

date=`date +%y.%m.%d`

git add .
git commit -m "$date"
git branch -M main
git push -u origin main
