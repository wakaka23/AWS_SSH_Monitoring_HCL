########################
# S3 Bucket
########################

# Define S3 Bucket for tfstate
locals {
  bucket = "terraform-tfstate-ssh-monitoring"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = local.bucket
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = local.bucket
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = local.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = local.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}