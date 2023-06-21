resource "random_id" "vault_auto_unseal" {
  count       = var.create ? 1 : 0
  byte_length = 4
  prefix      = var.name
}
 
# Auto Unseal KMS Keys
resource "aws_kms_key" "vault_auto_unseal" {
  count                   = var.create ? 1 : 0
  description             = "AWS KMS Customer-managed key used for Vault auto-unseal and encryption"
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = false
  is_enabled              = true
  deletion_window_in_days = 30

  tags = merge(var.tags, { "Name" = random_id.vault_auto_unseal[0].hex })

}

