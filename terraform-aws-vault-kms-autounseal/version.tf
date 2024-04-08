terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9"
    }

    http = {
      source = "hashicorp/http" 
      version = "~> 2.1"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.15"
}