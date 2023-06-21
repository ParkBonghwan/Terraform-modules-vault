variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}
 
variable "name" {
  description = "Name for resources, defaults to \"vault-auto-unseal\"."
  default     = "vault-auto-unseal"
}
 
variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map
  default     = {}
}