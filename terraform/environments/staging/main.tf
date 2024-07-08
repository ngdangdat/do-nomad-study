resource "digitalocean_project" "nomad_test" {
  name        = "nomad_test"
  description = "Nomad test project"
  purpose     = "Nomad"
  environment = "Development"
}

module "vpc" {
  source = "../../modules/vpc"
  name   = "adu-test-vpc"
}

module "nomad_cluster" {
  source       = "../../modules/nomad"
  vpc_name     = module.vpc.name
  project_name = digitalocean_project.nomad_test.name
  depends_on   = [module.vpc, digitalocean_project.nomad_test]
  agent_count  = 0
  server_count = 2
  bastion_addresses = ["58.187.140.100/24"]
}
