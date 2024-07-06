terraform {
  required_version = "~>1.9.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">=2.39.2"
    }
  }
  backend "s3" {
      // https://terraform-adu.sgp1.digitaloceanspaces.com
    // endpoint = "https://sgp1.digitaloceanspaces.com"
    endpoints = {
      s3 = "https://sgp1.digitaloceanspaces.com"
    }
    key                         = "terraform.tfstate"
    bucket                      = "terraform-adu"
    region                      = "ap-southeast-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum = true
    skip_metadata_api_check     = true
  }
}

variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

