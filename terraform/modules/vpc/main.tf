resource "digitalocean_vpc" "vpc" {
  name     = var.name
  region   = var.region
  ip_range = var.cidr
}
