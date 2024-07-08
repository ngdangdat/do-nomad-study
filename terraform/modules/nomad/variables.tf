variable "region" {
  type        = string
  description = "Region"
  default     = "sgp1"
}

variable "project_name" {
  type = string
}

variable "agent_count" {
  type        = number
  description = "Client node count"
  default     = 1
}

variable "agent_size" {
  type        = string
  description = "Client instance size/specs"
  default     = "s-2vcpu-4gb-intel"
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

variable "ssh_public_key_url" {
  type        = string
  description = "URL of the public ssh key to add to the droplets"
  default     = "https://github.com/ngdangdat.keys"
}

variable "username" {
  description = "Nomad sudo user"
  default     = "nomadu"
  type        = string
}

variable "datacenter" {
  description = "Nomad datacenter"
  default     = "dc1"
  type        = string
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC to put Nomad cluster in"
}

variable "nomad_ports" {
  default = {
    "api" : {
      "port" : 4646,
      "protocol" : "tcp"
    },
    "rpc" : {
      "port" : 4647,
      "protocol" : "tcp"
    },
    "serf" : {
      "port" : 4648,
      "protocol" : "tcp"
    }
  }
  type = map(
    object(
      {
        port     = number
        protocol = string
      }
    )
  )
}

variable "nomad_version" {
  type    = string
  default = "1.8.1"
}

variable "bastion_addresses" {
  type = list(string)
  default = []
}

