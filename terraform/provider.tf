terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"   # Any version 2.x is fine
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.1.0"
    }

    ansible = {
      source = "ansible/ansible"
      version = "1.3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}



