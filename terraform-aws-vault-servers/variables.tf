variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "name" {
  description = "Name for resources, defaults to \"vault-server\"."
  default     = "vault-server"
}

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map(any)
  default     = {}
}

variable "auto_unseal_arn" {
  description = "ARN of the AWS KMS key for Vault auto unsealing"
  default     = null
}

variable "domain_name" {
  type        = string
  description = "(Required) Vault domain name"
}

variable "certificate_body" {
  description = "Certificate for LB IAM server certificate."
  default     = null
}

variable "private_key" {
  description = "Private key for LB IAM server certificate."
  default     = null
}

variable "certificate_chain" {
  description = "Certificate chain for LB IAM server certificate."
  default     = null
}

variable "inst_type" {
  type        = string
  description = "EC2 instance type"
  default     = "m5.xlarge"
}

variable "ssh_key_pair_name" {
  type        = string
  description = "Name of SSH key pair for SSH access to vault instances"
}

variable "server_security_group_id" {
  description = "ID of the vault security group"
}

variable "instance_profile_name" {
  description = "Name of the vault instance profile"
  default     = null
}


variable "subnet_ids" {
  description = "Subnets where vm will be deployed"
  type        = list(any)
}

variable "lb_target_group_arns" {
  description = "ARN of the vault load balancer target group"
  type        = list(string)
  default     = null
}

variable "license_file" {
  description = "Vault license file path"
  default     = null
}

variable "inst_size" {
  description = "Number of Instances to configure a Vault Cluster"
  default     = 0
}

variable "use_auto_scaling" {
  default = false
}

variable "image_id" {
  description = "The AMI from which to launch the vault instance."
  default     = null
}

variable "install_by_pkg" {
  description = "true if Vault is installed by Package Manager, false if installed by Binary, defaults to true"
  type        = bool
  default     = true
}

variable "install_method" {
  description = "Method of installation for Vault: airgap, binary, pkgmgr"
  type        = string
  default     = "pkgmgr"

  validation {
    condition     = contains(["airgap", "binary", "pkgmgr"], var.install_method)
    error_message = "Invalid value for install_by variable. Allowed values are airgap, binary, and pkgmgr."
  }
}

variable "lb_use_https" {
  description = "Indicates whether to use HTTPS for the Vault load balancer"
  type        = bool
}

variable "vault_version" {
  description = "Vault version to use when installing Vault using Binary"
  default     = "1.12.1"
}

variable "use_autopilot_upgrade" {
  description = "Whether to enable vault auto upgrade"
  type        = bool
  default     = false
}

variable "vault_server_name" {
  description = "Name of the instance on which you want to configure the Vault cluster"
  type        = string
  default     = ""
}

variable "use_telemetry" {
  description = "Whether to generate Vault Telemetry metrics"
  type        = bool
  default     = false
}