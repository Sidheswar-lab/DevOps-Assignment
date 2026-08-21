#!/bin/bash
BUCKET_NAME="q11-website-$(date +%s)-$RANDOM"
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
echo "CREATING WEBSITE FILES"
cat > index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Q11 AWS Static Website</title>
</head>
<body>
    <h1>Welcome to My AWS Static Website</h1>
    <p>This website is hosted using Amazon S3.</p>
</body>
</html>
EOF
cat > error.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Error</title>
</head>
<body>
    <h1>404 - Page Not Found</h1>
    <p>The requested page does not exist.</p>
</body>
</html>
EOF
echo "CONFIGURING STATIC WEBSITE HOSTING"
aws s3api put-bucket-website \
    --bucket "$BUCKET_NAME" \
    --website-configuration '{
        "IndexDocument": {
            "Suffix": "index.html"
        },
        "ErrorDocument": {
            "Key": "error.html"
        }
    }'
echo "CREATING BUCKET POLICY"
POLICY_FILE="q11-website-policy.json"
cat > "$POLICY_FILE" <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF
echo "ATTACHING BUCKET POLICY"
aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file://"$POLICY_FILE"
echo "UPLOADING WEBSITE FILES"
aws s3 cp index.html "s3://$BUCKET_NAME/"
aws s3 cp error.html "s3://$BUCKET_NAME/"
echo "VERIFYING FILES"
aws s3 ls "s3://$BUCKET_NAME/"
WEBSITE_ENDPOINT="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "STATIC WEBSITE CREATED SUCCESSFULLY"
echo "Bucket: $BUCKET_NAME"
echo "Website Endpoint:"
echo "$WEBSITE_ENDPOINT"
