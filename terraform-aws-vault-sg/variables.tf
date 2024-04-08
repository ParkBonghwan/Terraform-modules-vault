variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "name" {
  description = "Name for resources, defaults to \"vault-server-sg\"."
  default     = "vault-server-sg"
}

variable "vpc_id" {
  description = "VPC ID to provision resources in."
}

variable "cidr_blocks" {
  description = "CIDR blocks for Security Groups."
  type        = list(any)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map(any)
  default     = {}
}

variable "use_consul" { 
  description = "Whether to use Consul as a vault backend"
  type = bool
  default = false
}
