terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }

  backend "s3" {
    bucket                      = "tfstate"
    key                         = "shortener/terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = "http://localhost:4566" }
    access_key                  = "test"
    secret_key                  = "test"
    use_path_style              = true
    use_lockfile                = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb     = "http://localhost:4566"
    iam          = "http://localhost:4566"
    lambda       = "http://localhost:4566"
    sts          = "http://localhost:4566"
    apigatewayv2 = "http://localhost:4566"
  }
}