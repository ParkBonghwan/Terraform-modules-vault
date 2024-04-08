variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "name" {
  description = "Name for resources, defaults to \"vault-lb-aws\"."
  default     = "vault-lb-aws"
}

variable "vpc_id" {
  description = "VPC ID to provision LB in."
}

variable "cidr_blocks" {
  description = "The CIDR block to set in the Security Group to restrict access to the LB."
  type        = list(any)
}

variable "subnet_ids" {
  description = "Subnet ID(s) to provision LB across."
  type        = list(any)
}

variable "is_internal_lb" {
  description = "Is an internal load balancer, defaults to true."
  default     = true
}

variable "use_https" {
  description = "Whether to enable https communication when using LB. Defaults to false, \"lb_cert_chain\", \"lb_cert\" and \"lb_private_key\" must be passed in if true"
  default     = false
}

variable "use_secondary" {
  description = "Use if you are configuring Vault as DR. This is just for testing purposes and you should actually have DR deployed in a different region."
  default     = false
}


variable "lb_cert" {
  description = "Certificate for LB IAM server certificate."
  default     = ""
}

variable "lb_private_key" {
  description = "Private key for LB IAM server certificate."
  default     = ""
}

variable "lb_cert_chain" {
  description = "Certificate chain for LB IAM server certificate."
  default     = ""
}

variable "lb_ssl_policy" {
  description = "SSL policy for LB, defaults to \"ELBSecurityPolicy-TLS-1-2-2017-01\"."
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "lb_bucket" {
  description = "S3 bucket override for LB access logs, `lb_bucket_override` be set to true if overriding"
  default     = ""
}

variable "lb_bucket_override" {
  description = "Override the default S3 bucket created for access logs with `lb_bucket`, defaults to false."
  default     = false
}

variable "lb_bucket_prefix" {
  description = "S3 bucket prefix for LB access logs."
  default     = ""
}

variable "lb_logs_enabled" {
  description = "S3 bucket LB access logs enabled, defaults to true."
  default     = true
}

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map(any)
  default     = {}
}

variable "lb_health_check_path" {
  type        = string
  description = "The endpoint to check for Vault's health status."
  default     = "/v1/sys/health"
}

variable "use_consul" {
  description = "Whether to use Consul as a vault backend"
  type        = bool
  default     = false
}
