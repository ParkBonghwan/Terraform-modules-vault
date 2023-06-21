output "vault-namespace-path" {
  description = "The full path of the namespace created."
  value = var.create? vault_namespace.namespace[0].path : null
}

output "vault-admin-token" {
  description = "The Vault token created for managing the namespace."
  value = var.create? vault_token.namespace-admin-token[0].client_token : null
}