#!/bin/bash
POLICY_NAME="MyCustomPolicy"
POLICY_FILE="policy.json"
echo "Creating IAM Policy JSON File"
cat > "$POLICY_FILE" <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
echo "Policy file created: $POLICY_FILE"
echo
echo "Policy Content"
cat "$POLICY_FILE"
echo
echo "Creating IAM Policy in AWS"
aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "file://$POLICY_FILE"
if [ $? -eq 0 ]; then
    echo
    echo "IAM policy '$POLICY_NAME' created successfully."
else
    echo
    echo "Failed to create IAM policy."
    exit 1
fi
