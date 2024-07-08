data "digitalocean_image" "ubuntu" {
  slug = "ubuntu-20-04-x64"
}

data "http" "ssh_key" {
  url = var.ssh_public_key_url
}

data "digitalocean_vpc" "nomad" {
  name = var.vpc_name
}

data "digitalocean_project" "p" {
  name = var.project_name
}

resource "digitalocean_tag" "nomad" {
  name = "nomad"
}

resource "digitalocean_tag" "nomad_server" {
  name = "nomad_server"
}

resource "digitalocean_tag" "nomad_client" {
  name = "nomad_client"
}

resource "digitalocean_ssh_key" "nomad" {
  name       = "Nomad servers ssh key"
  public_key = data.http.ssh_key.response_body
  lifecycle {
    precondition {
      condition     = contains([201, 200, 204], data.http.ssh_key.status_code)
      error_message = "Status code is not OK"
    }
  }
}

resource "digitalocean_droplet" "server" {
  count      = var.server_count
  image      = data.digitalocean_image.ubuntu.slug
  name       = "server-${count.index}"
  region     = var.region
  size       = var.server_size
  ssh_keys   = [digitalocean_ssh_key.nomad.id]
  vpc_uuid   = data.digitalocean_vpc.nomad.id
  volume_ids = [tostring(digitalocean_volume.nomad_data[count.index].id)]
  user_data = templatefile(
    "${path.module}/templates/userdata.tftpl",
    {
      nomad_version = var.nomad_version
      server        = true
      username      = var.username
      datacenter    = var.datacenter
      servers       = var.server_count
      ssh_pub_key   = data.http.ssh_key.response_body
      tag           = digitalocean_tag.nomad_server.name
      region        = data.digitalocean_vpc.nomad.region
      // update to use vault later
      join_token = "dummy-auto-join-token"
      project    = data.digitalocean_project.p.name
      count      = count.index
    }
  )
  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
  }
  provisioner "remote-exec" {
    script = "${path.module}/provision/start-nomad.sh"
  }
}

resource "digitalocean_droplet" "client" {
  depends_on    = [digitalocean_droplet.server]
  count         = var.agent_count
  image         = data.digitalocean_image.ubuntu.slug
  name          = "nomad-client-${count.index}"
  region        = data.digitalocean_vpc.nomad.region
  size          = var.agent_size
  vpc_uuid      = data.digitalocean_vpc.nomad.id
  ipv6          = false
  backups       = false
  monitoring    = true
  tags          = ["nomad-client", "auto-destroy"]
  ssh_keys      = [digitalocean_ssh_key.nomad.id]
  droplet_agent = true
  user_data = templatefile(
    "${path.module}/templates/userdata.tftpl",
    {
      nomad_version = var.nomad_version
      server        = false
      username      = var.username
      datacenter    = var.datacenter
      servers       = var.agent_count
      ssh_pub_key   = data.http.ssh_key.response_body
      tag           = "nomad-client"
      region        = data.digitalocean_vpc.nomad.region
      // join_token    = data.vault_generic_secret.join_token.data["autojoin_token"]
      join_token = "dummy-auto-join-token"
      project    = data.digitalocean_project.p.name
      count      = count.index
    }
  )
  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
  }
  provisioner "remote-exec" {
    script = "${path.module}/provision/start-nomad.sh"
  }
  # lifecycle {
  #   postcondition {
  #     condition     = contains([201, 200, 204, 503], data.http.nomad_server_health.status_code)
  #     error_message = "Nomad service is not healthy"
  #   }
  # }
}

resource "digitalocean_loadbalancer" "external" {
  name     = "nomad-external"
  region   = data.digitalocean_vpc.nomad.region
  vpc_uuid = data.digitalocean_vpc.nomad.id

  forwarding_rule {
    entry_port  = 80
    target_port = var.nomad_ports.api.port
    #tfsec:ignore:digitalocean-compute-enforce-https
    entry_protocol  = "http"
    target_protocol = "http"
  }

  healthcheck {
    protocol = "http"
    port     = var.nomad_ports.api.port
    path     = "/ui"
  }

  # healthcheck {
  #   protocol = "http"
  #   port     = var.nomad_ports.api.port
  #   path     = "/v1/agent/health?type=server"
  # }

  droplet_tag = "nomad-server"
}

resource "digitalocean_firewall" "nomad" {
  for_each = var.nomad_ports
  name     = "nomad-server-${each.key}"
  droplet_ids = concat(
    digitalocean_droplet.server[*].id
  )
  tags = [digitalocean_tag.nomad.name, digitalocean_tag.nomad_server.name]
  inbound_rule {
    protocol   = each.value.protocol
    port_range = each.value.port
    # source_tags      = ["nomad-server"]
    source_addresses = digitalocean_droplet.server[*].ipv4_address_private
  }

  inbound_rule {
    protocol   = "tcp"
    port_range = "1-65535"
    source_addresses = var.bastion_addresses
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

resource "digitalocean_volume" "nomad_data" {
  count                   = var.server_count
  region                  = data.digitalocean_vpc.nomad.region
  name                    = "nomad-data-${count.index}"
  size                    = "1"
  initial_filesystem_type = "ext4" 
  tags                    = [digitalocean_tag.nomad.name]
}

resource "digitalocean_project_resources" "nomad" {
  project = data.digitalocean_project.p.id
  resources = concat(
    tolist(digitalocean_droplet.server[*].urn),
    tolist(digitalocean_droplet.client[*].urn),
    [digitalocean_loadbalancer.external.urn],
  )
}
