locals {
  policy_prefix = var.namespace != "" ? "${var.namespace}/" : ""
  app_environments = flatten([
    for app in var.applications : [
      for env in app.envs : "${app.name}/${env}"
    ]
  ])
  app_names = flatten([
    for app in var.applications : [
      for env in app.envs : "${app.name}-${env}"
    ]
  ])  
}

resource "vault_mount" "application-root-per-env" {
  count     = var.create ?  length(local.app_environments) : 0
  namespace = var.namespace != "" ? var.namespace : null
  path      = local.app_environments[count.index] 
  type      = "kv-v2"
}

resource "vault_policy" "secretprovider" {
  count     = var.create ?  length(local.app_environments) : 0
  name      = "${local.app_names[count.index]}-secret-provider-policy"
  namespace = var.namespace != "" ? var.namespace : null
  policy    = <<-EOT
  path "${local.policy_prefix}${local.app_environments[count.index]}/*" {
    capabilities = ["create", "update", "delete", "list"]
  }
  EOT
}

resource "vault_policy" "secretconsumer" {
  count     = var.create ?  length(local.app_environments) : 0
  name      = "${local.app_names[count.index]}-secret-consumer-policy"
  namespace = var.namespace != "" ? var.namespace : null
  policy    = <<-EOT
  path "${local.policy_prefix}${local.app_environments[count.index]}/*" {
    capabilities = ["read","list"]
  }
  EOT
}

resource "vault_policy" "secretadmin" {
  count     = var.create ?  length(local.app_environments) : 0
  name      = "${local.app_names[count.index]}-secret-admin-policy"
  namespace = var.namespace != "" ? var.namespace : null
  policy    = <<-EOT
  path "${local.policy_prefix}${local.app_environments[count.index]}/*" {
    capabilities = ["read","create", "update", "delete", "list"]
  }
  EOT
}
 
resource "vault_approle_auth_backend_role" "secret-provider-approle" {
  count          = var.create && var.enable_approle ? length(local.app_names) : 0
  backend        = var.approle_path
  namespace      = var.namespace != "" ? var.namespace : null
  role_name      = "${local.app_names[count.index]}-secret-provider"
  token_policies = ["${local.app_names[count.index]}-secret-provider-policy"]
}

resource "vault_approle_auth_backend_role" "secret-consumer-approle" {
  count          = var.create && var.enable_approle ? length(local.app_names) : 0
  backend        = var.approle_path
  namespace      = var.namespace != "" ? var.namespace : null
  role_name      = "${local.app_names[count.index]}-secret-consumer"
  token_policies = ["${local.app_names[count.index]}-secret-consumer-policy"]
}

resource "vault_approle_auth_backend_role" "secret-admin-approle" {
  count          = var.create && var.enable_approle ? length(local.app_names) : 0
  backend        = var.approle_path
  namespace      = var.namespace != "" ? var.namespace : null
  role_name      = "${local.app_names[count.index]}-secret-admin"
  token_policies = ["${local.app_names[count.index]}-secret-admin-policy"]
}