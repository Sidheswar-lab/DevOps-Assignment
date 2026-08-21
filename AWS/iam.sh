#!/bin/bash

USERNAME="2341013023"

echo "Creating IAM User"
aws iam create-user --user-name "$USERNAME"

aws iam attach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam attach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

aws iam attach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

echo
echo "IAM user created successfully."

aws iam get-user --user-name "$USERNAME" > user_report.txt

echo
echo "IAM USER REPORT"

sed -E 's/[{},"]//g' user_report.txt > cleaned_report.txt

echo "Username:"
awk -F': ' '/UserName:/ {print $2}' cleaned_report.txt

echo "User ID:"
awk -F': ' '/UserId:/ {print $2}' cleaned_report.txt

echo "ARN:"
awk -F': ' '/Arn:/ {print $2}' cleaned_report.txt

echo "Created Date:"
awk -F': ' '/CreateDate:/ {print $2}' cleaned_report.txt

echo
echo "ATTACHED POLICIES"

aws iam list-attached-user-policies \
    --user-name "$USERNAME" > policies.txt

sed -E 's/[{},"]//g' policies.txt | \
awk -F': ' '/PolicyName:/ {print $2}'

echo
echo "Report Generated Successfully"
