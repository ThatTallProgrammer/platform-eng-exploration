terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.4.2"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.4.1"
    }
  }
  backend "s3" {
    bucket       = "platform-eng-exploration"
    key          = "terraform.tfstate" 
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true 
  }
}
