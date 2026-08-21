#!/bin/bash

BUCKET_NAME="q10-bucket-$(date +%s)-$RANDOM"
REGION=$(aws configure get region)

if [ -z "$REGION" ]; then
    REGION="eu-north-1"
fi

echo "CREATING S3 BUCKET"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"

aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

echo "CREATING TEXT FILES"

echo "This is the first file for Q10." > file1.txt
echo "This is the second file for Q10." > file2.txt
echo "This is the third file for Q10." > file3.txt

echo "CREATING BUCKET POLICY"

ACCOUNT_ID=$(aws sts get-caller-identity \
    --query Account \
    --output text)

POLICY_FILE="q10-bucket-policy.json"

cat > "$POLICY_FILE" <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAccountAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$ACCOUNT_ID:root"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

echo "ATTACHING BUCKET POLICY"

aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file://"$POLICY_FILE"

echo "UPLOADING FILES"

aws s3 cp file1.txt "s3://$BUCKET_NAME/"
aws s3 cp file2.txt "s3://$BUCKET_NAME/"
aws s3 cp file3.txt "s3://$BUCKET_NAME/"

echo "VERIFYING UPLOADED FILES"

aws s3 ls "s3://$BUCKET_NAME/"

echo "Q10 COMPLETED SUCCESSFULLY"

echo "Bucket: $BUCKET_NAME"
