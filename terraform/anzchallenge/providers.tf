terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            versoin = "~> 3.2"
        }

        random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    }
}

provider "aws" {
    region = var.region
   
}