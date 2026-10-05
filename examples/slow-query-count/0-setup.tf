terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.92.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Existing private subnets for the example database."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Existing security groups allowing the required database traffic."
}

variable "sns_topic" {
  type        = string
  description = "Existing SNS topic receiving database alarms."
}
