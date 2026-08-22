#!/bin/bash
echo "Hello World!!"
echo "Start of the program..."
mkdir devops
touch devops/testing
cp devops/testing devops/testing.bak
echo "Before changing the permission"
ls -l devops/
chmod 444 devops/testing.bak
echo "After changing the permission"
ls -l devops/
echo "Let's delete the folder recursively.."
rm -r devops
echo "End of thr program"
