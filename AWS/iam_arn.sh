#!/bin/bash

echo "AWS IAM USERS AND POLICIES"
aws iam list-users \
    --query 'Users[*].UserName' \
    --output text | tr '\t' '\n' |
while read USERNAME
do
    echo
    echo "User: $USERNAME"

    ARN=$(aws iam get-user \
        --user-name "$USERNAME" \
        --query 'User.Arn' \
        --output text)

    echo "User ARN: $ARN"
    echo
    echo "Attached Policies:"
    aws iam list-attached-user-policies \
        --user-name "$USERNAME" \
        --query 'AttachedPolicies[*].PolicyName' \
        --output text
done
