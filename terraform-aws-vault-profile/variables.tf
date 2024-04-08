variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}
 
variable "name" {
  description = "Name for resources, defaults to \"vault-profile\"."
  default     = "vault-profile"
}

variable "auto_unseal_kms_key_arn" {
  description = "ARN of the KMS key for automatic unsealing"
  default = null
}

variable "secretsmanager_secret_arn" {
  description = "ARN of the Secret manager for saving vault init result"
  default = null
}

variable "snapshot_bucket_arn" {
  description = "ARN of the S3 Bucket for saving vault snapshot"
  default = null
}

variable "audit_log_group_arn" {
  description = "ARN of the log group for saving vault audit log"
  default = null
}

variable "iam_permissions_boundary" {
  description = "IAM Managed Policy to serve as permissions boundary for IAM Role"
  type        = string
  default     = null
}
