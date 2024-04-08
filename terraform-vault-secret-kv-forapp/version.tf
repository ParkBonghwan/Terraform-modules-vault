terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.13"
    }
  }

  required_version = ">= 0.15"
}