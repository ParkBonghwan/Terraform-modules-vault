output "vault_server_sg_id" {
  value = var.create? aws_security_group.vault_server[0].id : null
}