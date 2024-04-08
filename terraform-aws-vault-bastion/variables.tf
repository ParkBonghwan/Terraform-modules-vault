variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "name" {
  description = "Name for resources, defaults to \"vault\"."
  default     = "vault"
}

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map
  default     = {}
}

variable "subnet_id" {
    description = "The VPC Subnet ID to launch in"
}

variable "instance_type" {
    description = "The type of instance to start"
    default = "t3.small"
}

variable "ssh_key_name" {
  description = "AWS key name you will use to access the Bastion host instance(s), defaults to generating an SSH key for you."
  default     = ""
}

variable "ssh_key_override" {
  description = "Override the default SSH key and pass in your own, defaults to false."
  default     = false
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile"
  default = null
}

variable "vpc_id" {
  description = "VPC ID" 
}