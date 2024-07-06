data "digitalocean_image" "ubuntu" {
  slug = "ubuntu-20-04-x64"
}

resource "digitalocean_droplet" "server" {
  count  = var.server_count
  image  = data.digitalocean_image.ubuntu.slug
  name   = "server-${count.index}"
  region = var.region
  size   = var.server_size
}
