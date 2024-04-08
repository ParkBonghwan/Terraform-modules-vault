variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "applications" {
  description = "List of objects for the Vault identity entity"
  type = list(object({
    name = string
    envs = list(string)
  }))
  default = []
}

variable "approle_path" {
  description = "The path of AppRole auth backend, eg, approle"
  type        = string
  default     = "approle"
}

variable "enable_approle" {
  description = "If approle roles should be enabled for the application"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Specifies the vault namespace to which the application belongs"
  type        = string
  default     = ""
}
