variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "name" {
  description = "Name for resources, defaults to \"vault-aws-network\"."
  default     = "vault-aws-network"
}

variable "create_vpc" {
  description = "Determines whether a VPC should be created or if a VPC ID will be passed in."
  default     = true
}

variable "vpc_id" {
  description = "VPC ID to override, must be entered if \"create_vpc\" is false."
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR block, defaults to \"10.139.0.0/16\"."
  default     = "10.139.0.0/16"
}

variable "vpc_cidrs_public" {
  description = "VPC CIDR blocks for public subnets, defaults to \"10.139.1.0/24\", \"10.139.2.0/24\", and \"10.139.3.0/24\"."
  type        = list(any)
  default     = ["10.139.1.0/24", "10.139.2.0/24", "10.139.3.0/24", ]
}

variable "nat_count" {
  description = "Number of NAT gateways to provision across public subnets, defaults to public subnet count."
  default     = 0
}

variable "vpc_cidrs_private" {
  description = "VPC CIDR blocks for private subnets, defaults to \"10.139.11.0/24\", \"10.139.12.0/24\", and \"10.139.13.0/24\"."
  type        = list(any)
  default     = ["10.139.11.0/24", "10.139.12.0/24", "10.139.13.0/24", ]
}

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map(any)
  default     = {}
}
