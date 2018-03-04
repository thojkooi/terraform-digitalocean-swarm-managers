provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_droplet" "manager" {
  ssh_keys           = "${var.ssh_keys}"
  image              = "${var.image}"
  region             = "${var.region}"
  size               = "${var.size}"
  private_networking = true
  backups            = "${var.backups}"
  ipv6               = false
  tags               = ["${var.tags}"]
  user_data          = "${var.user_data}"
  count              = "${var.total_instances}"
  name               = "${format("%s-%02d.%s.%s", var.name, count.index + 1, var.region, var.domain)}"

  connection {
    type        = "ssh"
    user        = "${var.provision_user}"
    private_key = "${file("${var.provision_ssh_key}")}"
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! $(sudo docker info) ]; do sleep 2; done",

      # TODO: Handle failure during swarm init, only run this if manager node is not in a swarm
      "if [ ${count.index} -eq 0 ]; then sudo docker swarm init --advertise-addr ${digitalocean_droplet.manager.0.ipv4_address_private}; exit 0; fi",
    ]
  }
}

data "external" "swarm_tokens" {
  program = ["bash", "${path.module}/scripts/get-swarm-join-tokens.sh"]

  query = {
    host        = "${element(digitalocean_droplet.manager.*.ipv4_address, 0)}"
    user        = "${var.provision_user}"
    private_key = "${var.provision_ssh_key}"
  }
}

#
resource "null_resource" "bootstrap" {
  count = "${var.total_instances}"

  triggers {
    cluster_instance_ids = "${join(",", digitalocean_droplet.manager.*.id)}"
  }

  connection {
    host        = "${element(digitalocean_droplet.manager.*.ipv4_address, count.index)}"
    type        = "ssh"
    user        = "${var.provision_user}"
    private_key = "${file("${var.provision_ssh_key}")}"
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! $(sudo docker info) ]; do sleep 2; done",
      "if [ ${count.index} -gt 0 ] && [! sudo docker info | grep -q \"Swarm: active\" ]; then sudo docker swarm join --token ${lookup(data.external.swarm_tokens.result, "manager")} ${element(digitalocean_droplet.manager.*.ipv4_address_private, 0)}:2377; exit 0; fi",
    ]
  }
}
