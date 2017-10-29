# Terraform - DigitalOcean Docker Swarm mode managers

Terraform module to provision and bootstrap a Docker Swarm mode cluster with multiple managers using a private network on DigitalOcean.

[![CircleCI](https://circleci.com/gh/thojkooi/terraform-digitalocean-swarm-managers/tree/master.svg?style=svg)](https://circleci.com/gh/thojkooi/terraform-digitalocean-swarm-managers/tree/master)

- [Requirements](#requirements)
- [Usage](#usage)
- [Examples](#examples)

## Requirements

- Terraform >= 0.10.6
- Digitalocean account / API token with write access
- SSH Keys added to your DigitalOcean account
- [jq](https://github.com/stedolan/jq)

## Usage

```hcl
module "swarm-cluster" {
  source          = "github.com/thojkooi/terraform-digitalocean-swarm-managers"
  domain          = "do.example.com"
  total_instances = 3
  do_token        = "${var.do_token}"
  ssh_keys        = [1234, 1235, ...]
}
```

### SSH Key

Terraform uses an SSH key to connect to the created droplets in order to issue `docker swarm join` commands. By default this uses `~/.ssh/id_rsa`. If you wish to use a different key, you can modify this using the variable `provision_ssh_key`. You also need to ensure the public key is added to your DigitalOcean account and it's ID is listed in the `ssh_keys` list.

### Notes

This module does not set up a firewall or modifies any other security settings. Please configure this by providing user data for the manager nodes. Also set up firewall rules on DigitalOcean for the cluster, to ensure only cluster members can access the internal Swarm ports.

## Examples

For examples, see the [examples directory](https://github.com/thojkooi/terraform-digitalocean-swarm-managers/tree/master/examples).

## Swarm set-up

First a single Swarm mode manager is provisioned. This is the leader node. If you have additional manager nodes, these will be provisioned after this step. Once the manager nodes have been provisioned, Terraform will initialize the Swarm on the first manager node and retrieve the join tokens. It will then have all the managers join the cluster.

If the cluster is already up and running, Terraform will check with the first leader node to refresh the join tokens. It will join any additional manager nodes that are provisioned automagically to the Swarm.
