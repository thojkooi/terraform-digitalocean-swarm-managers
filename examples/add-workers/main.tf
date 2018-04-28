variable "do_token" {}

provider "digitalocean" {
  token = "${var.do_token}"
}

variable "ssh_keys" {
  type = "list"
}

module "swarm-cluster-managers" {
  # source = "github.com/thojkooi/terraform-digitalocean-swarm-managers"
  source          = "../../"
  total_instances = 1
  region          = "ams3"
  do_token        = "${var.do_token}"
  ssh_keys        = "${var.ssh_keys}"
  domain          = "do.example.com"
}

module "workers" {
  source   = "github.com/thojkooi/terraform-digitalocean-swarm-workers"
  do_token = "${var.do_token}"

  size            = "s-1vcpu-1gb"
  name            = "web"
  region          = "ams3"
  domain          = "do.example.com"
  total_instances = 1
  ssh_keys        = "${var.ssh_keys}"

  manager_public_ip  = "${element(module.swarm-cluster-managers.ipv4_addresses, 0)}"
  manager_private_ip = "${element(module.swarm-cluster-managers.ipv4_addresses_private, 0)}"
  join_token         = "${module.swarm-cluster-managers.worker_token}"
}
