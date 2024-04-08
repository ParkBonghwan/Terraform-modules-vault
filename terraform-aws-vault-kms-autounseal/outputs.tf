 output "vault_auto_unseal_key_arn" {
  value = var.create ? aws_kms_key.vault_auto_unseal[0].arn : null
}