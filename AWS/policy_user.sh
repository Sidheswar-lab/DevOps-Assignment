#!/bin/bash
USERNAME="2341013023"
POLICY_NAME="CustomAdministratorPolicy"
POLICY_FILE="admin-policy.json"
echo "AWS IAM ADMINISTRATIVE USER"
cat > "$POLICY_FILE" <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
echo
echo "Administrative policy file created."
if aws iam get-user --user-name "$USERNAME" >/dev/null 2>&1; then
    echo "User $USERNAME already exists."
else
    echo "Creating IAM user: $USERNAME"

    if aws iam create-user --user-name "$USERNAME"; then
        echo "User created successfully."
    else
        echo "ERROR: Failed to create IAM user."
        exit 1
    fi
fi
echo
echo "Creating administrative IAM policy..."
POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "file://$POLICY_FILE" \
    --query 'Policy.Arn' \
    --output text 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Policy may already exist. Getting existing policy ARN..."
    POLICY_ARN=$(aws iam list-policies \
        --scope Local \
        --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" \
        --output text)
fi
echo "Policy ARN: $POLICY_ARN"
echo
echo "Attaching administrative policy to $USERNAME..."
aws iam attach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn "$POLICY_ARN"
if [ $? -eq 0 ]; then
    echo "Policy attached successfully."
else
    echo "ERROR: Failed to attach policy."
    exit 1
fi
echo
echo "ATTACHED POLICIES"
aws iam list-attached-user-policies \
    --user-name "$USERNAME" \
    --query 'AttachedPolicies[*].[PolicyName,PolicyArn]' \
    --output table
echo
echo "IAM user '$USERNAME' has administrative access."
