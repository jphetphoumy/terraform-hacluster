variable "do_token" {}
variable "server_name" {
  description = "list of server name"
  type  = list(string)
  default = ["primary", "secondary"]
}


provider "digitalocean" {
    token = "${var.do_token}"
}

data "digitalocean_ssh_key" "ssh_key" {
    name = "Window_new"
}

data "digitalocean_droplet_snapshot" "heartbeat" {
  name_regex  = "^heartbeat"
  region      = "lon1"
  most_recent = true
}

resource "digitalocean_droplet" "rabbitmq" {
    count = 2
    image = data.digitalocean_droplet_snapshot.heartbeat.id
    name = "rabbitmq-${var.server_name[count.index]}"
    region = "lon1"
    size = "s-1vcpu-1gb"
    ssh_keys = [data.digitalocean_ssh_key.ssh_key.id]
}

resource "digitalocean_floating_ip" "rabbitmq" {
  region = "${var.region}"
}

data "template_file" "init_ansible_inventory" {
    template = "${file("ansible_inventory.tpl")}"
    vars = {
        primary = "${digitalocean_droplet.rabbitmq[0].ipv4_address}"
        secondary = "${digitalocean_droplet.rabbitmq[1].ipv4_address}"
        floating_ip = "${digitalocean_floating_ip.rabbitmq.ip_address}"
    }
}

resource "null_resource" "update_inventory" {
    triggers = {
        template = "${data.template_file.init_ansible_inventory.rendered}"
    }

    provisioner "local-exec" {
        command = "echo '${data.template_file.init_ansible_inventory.rendered}' > ../ansible/hosts"
    }
}

output "rabbitmq1_ip_address" {
    value = digitalocean_droplet.rabbitmq[0].ipv4_address
}

output "rabbitmq2_ip_address" {
    value = digitalocean_droplet.rabbitmq[1].ipv4_address
}

output "floating_ip" {
    value = digitalocean_floating_ip.rabbitmq.ip_address
}