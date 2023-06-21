output "result" {
  value = {
    for i in range(length(vault_mount.application-root-per-env)) :
    vault_mount.application-root-per-env[i].path =>
    {
      secret_path  = vault_mount.application-root-per-env[i].path,
      approle_name = var.enable_approle ? vault_approle_auth_backend_role.secret-provider-approle[i].role_name : null,
      namespace    = var.namespace
    }
  }
}
