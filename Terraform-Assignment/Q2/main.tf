terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0"
}
provider "aws" {
  region = "eu-north-1"
}
resource "aws_s3_bucket" "q2_bucket" {
  bucket = "q2-static-website-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "q2-static-website"
  }
}
data "aws_caller_identity" "current" {}
resource "aws_s3_bucket_public_access_block" "q2_public_access" {
  bucket = aws_s3_bucket.q2_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_website_configuration" "q2_website" {
  bucket = aws_s3_bucket.q2_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.q2_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Q2 Terraform Website</title>
</head>
<body>
    <h1>Welcome to My Terraform S3 Website</h1>
    <p>This website is hosted using Amazon S3.</p>
</body>
</html>
EOF
  depends_on = [
    aws_s3_bucket_public_access_block.q2_public_access
  ]
}
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.q2_bucket.id
  key          = "error.html"
  content_type = "text/html"
  content = <<EOF
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
  depends_on = [
    aws_s3_bucket_public_access_block.q2_public_access
  ]
}
resource "aws_s3_bucket_policy" "q2_policy" {
  bucket = aws_s3_bucket.q2_bucket.id

  depends_on = [
    aws_s3_bucket_public_access_block.q2_public_access
  ]
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.q2_bucket.arn}/*"
      }
    ]
  })
}
output "bucket_name" {
  value = aws_s3_bucket.q2_bucket.bucket
}
output "bucket_arn" {
  value = aws_s3_bucket.q2_bucket.arn
}
output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.q2_website.website_endpoint
}
