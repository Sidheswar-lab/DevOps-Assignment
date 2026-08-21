#!/bin/bash
ROLE_NAME="EC2S3AccessRole"
POLICY1="arn:aws:iam::aws:policy/AmazonEC2FullAccess"
POLICY2="arn:aws:iam::aws:policy/AmazonS3FullAccess"
TRUST_POLICY="trust-policy.json"
echo "AWS IAM ROLE CREATION"
cat > "$TRUST_POLICY" <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
echo "Trust policy file created."
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "Role $ROLE_NAME already exists."
else
    echo "Creating IAM role: $ROLE_NAME"

    if aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "file://$TRUST_POLICY"; then
        echo "Role created successfully."
    else
        echo "ERROR: Failed to create IAM role."
        exit 1
    fi
fi
echo "Attaching EC2FullAccess policy..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY1"

if [ $? -eq 0 ]; then
    echo "EC2FullAccess policy attached successfully."
else
    echo "ERROR: Failed to attach EC2 policy."
    exit 1
fi
echo "Attaching S3FullAccess policy..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY2"
if [ $? -eq 0 ]; then
    echo "S3FullAccess policy attached successfully."
else
    echo "ERROR: Failed to attach S3 policy."
    exit 1
fi
echo "ATTACHED POLICIES"
aws iam list-attached-role-policies \
    --role-name "$ROLE_NAME" \
    --query 'AttachedPolicies[*].[PolicyName,PolicyArn]' \
    --output table

echo "IAM role '$ROLE_NAME' created successfully."
