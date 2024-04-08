variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "server_ip" {
  description = "Public IP of the Vault bastion server"
  type        = string
}

variable "private_key_local_path" {
  description = "Local path to the private key"
  type        = string
}

variable "private_file_local_path" {
  description = "Local path to the private file"
  type        = string
}

variable "private_file_remote_path" {
  description = "Remote path to copy the private file"
  type        = string
}

variable "server_user" {
  description = "Username for SSH connection"
  type        = string
}

variable "permissions" {
  type    = string
  default = "400"
}

