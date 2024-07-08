variable "name" {
  type = string
}

variable "region" {
  type    = string
  default = "sgp1"
}

variable "cidr" {
  type        = string
  description = "Default 65535"
  default     = "10.10.0.0/16"
}
