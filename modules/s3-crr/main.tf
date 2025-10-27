locals {
  primary_bucket   = "${var.project_name}-primary-${var.unique_suffix}"
  secondary_bucket = "${var.project_name}-secondary-${var.unique_suffix}"
}

# Primary bucket (website-enabled)
resource "aws_s3_bucket" "primary" {
  bucket = local.primary_bucket
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_website_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

# Secondary bucket (website-enabled)
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = local.secondary_bucket
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_website_configuration" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

# IAM role for replication
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_iam_role" "replication" {
  name = "${var.project_name}-s3-replication-role-${var.unique_suffix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication" {
  name = "${var.project_name}-s3-replication-policy-${var.unique_suffix}"
  role = aws_iam_role.replication.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Resource : [aws_s3_bucket.primary.arn]
      },
      {
        Effect : "Allow",
        Action : [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        Resource : ["${aws_s3_bucket.primary.arn}/*"]
      },
      {
        Effect : "Allow",
        Action : [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:PutObjectTagging"
        ],
        Resource : ["${aws_s3_bucket.secondary.arn}/*"]
      }
    ]
  })
}

# Bucket policy to allow replication to destination
resource "aws_s3_bucket_policy" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = aws_iam_role.replication.arn },
      Action    = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ObjectOwnerOverrideToBucketOwner", "s3:PutObjectTagging"],
      Resource : ["${aws_s3_bucket.secondary.arn}/*"]
    }]
  })
}

# Replication configuration (Primary -> Secondary)
resource "aws_s3_bucket_replication_configuration" "this" {
  depends_on = [aws_s3_bucket_versioning.primary, aws_s3_bucket_versioning.secondary, aws_iam_role_policy.replication]
  bucket     = aws_s3_bucket.primary.id
  role       = aws_iam_role.replication.arn
  rule {
    id     = "replicate-all"
    status = var.replication_enabled ? "Enabled" : "Disabled"
    delete_marker_replication { status = "Enabled" }
    destination {
      account       = data.aws_caller_identity.current.account_id
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
      access_control_translation { owner = "Destination" }
    }
    filter {}
  }
}

# Website endpoints
data "aws_s3_bucket" "primary" { bucket = aws_s3_bucket.primary.bucket }
data "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.bucket
}

output "primary_bucket_name" { value = aws_s3_bucket.primary.bucket }
output "secondary_bucket_name" { value = aws_s3_bucket.secondary.bucket }
output "primary_website_endpoint" { value = aws_s3_bucket_website_configuration.primary.website_endpoint }
output "secondary_website_endpoint" { value = aws_s3_bucket_website_configuration.secondary.website_endpoint }
