# Vault namespace,policy and admin token for namespaces
resource "vault_namespace" "namespace" {
  count = var.create ? 1 : 0
  path  = var.name
}

resource "vault_policy" "namespace-admin-policy" {
  count  = var.create ? 1 : 0 
  name   = "${var.name}-admin-policy"
  policy = <<-EOT
  # Manage namespaces

  #adding below to allow creation of child token
  path "auth/token/create" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }

  path "${vault_namespace.namespace[0].path}/sys/namespaces/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  # Manage policies
  path "${vault_namespace.namespace[0].path}/sys/policies/acl/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  # List policies
  path "${vault_namespace.namespace[0].path}/sys/policies/acl" {
    capabilities = ["list"]
  }

  # Enable and manage secrets engines
  path "${vault_namespace.namespace[0].path}/sys/mounts/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }

  # List available secrets engines
  path "${vault_namespace.namespace[0].path}/sys/mounts" {
    capabilities = [ "read" ]
  }

  # Create and manage entities and groups
  path "${vault_namespace.namespace[0].path}/identity/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }

  # Manage tokens
  path "${vault_namespace.namespace[0].path}/auth/token/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  # Manage secrets at '*'
  path "${vault_namespace.namespace[0].path}/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }
  EOT
}

resource "vault_token" "namespace-admin-token" {
  count           = var.create ? 1 : 0
  policies        = [vault_policy.namespace-admin-policy[0].name]
  renewable       = true
  no_parent       = true
  ttl             = "768h"
  renew_min_lease = 43200
  renew_increment = 86400
}
