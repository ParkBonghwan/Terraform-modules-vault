resource "random_string" "lower" {
  length  = 8
  upper   = false
  lower   = true
  numeric = false
  special = false
}

# Snapshot S3 Bucket 
locals {
  bucket_name = format("%s-%s", lower(var.name), random_string.lower.result)
}

resource "aws_s3_bucket" "vault_snapshot" {
  count         = var.create ? 1 : 0
  bucket        = local.bucket_name
  tags          = merge(var.tags, { "Name" = local.bucket_name })
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "vault_snapshot" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.vault_snapshot[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vault_snapshot" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.vault_snapshot[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "vault_snapshot" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.vault_snapshot[count.index].id

  rule {
    id = "logs"

    expiration {
      days = 90
    }

    filter {
      and {
        prefix = ""
      }
    }

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}
