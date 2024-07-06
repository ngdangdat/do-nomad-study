variable "region" {
  type        = string
  description = "Region"
  default     = "sgp1"
}

variable "server_size" {
  type        = string
  description = "Server instance size/specs"
  default     = "s-1vcpu-1gb-intel"
}

variable "server_count" {
  type        = number
  description = "Server node count"
  default     = 1
}

