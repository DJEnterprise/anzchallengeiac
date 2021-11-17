terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            versoin = "~> 3.20.0"
        }

      random = {
          source  = "hashicorp/random"
          version = "3.1.0"
       }
    }
}
