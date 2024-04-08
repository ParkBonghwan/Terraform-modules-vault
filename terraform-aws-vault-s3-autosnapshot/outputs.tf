 output "vault_s3_snapshot_arn" {
  value = var.create? aws_s3_bucket.vault_snapshot[0].arn : null
}