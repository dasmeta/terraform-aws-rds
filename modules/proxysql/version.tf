terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
}
