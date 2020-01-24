variable "do_token" {}
variable "server_name" {
  description = "list of server name"
  type  = list(string)
  default = ["primary", "secondary"]
}
variable "ssh_fingerprint" {}
variable "private_key" {}
variable "public_key" {}

provider "digitalocean" {
    token = "${var.do_token}"
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
    ssh_keys = ["${var.ssh_fingerprint}"]

    provisioner "remote-exec" {
        script = "${"deploy.sh"}"

        connection {
            type = "ssh"
            user = "root"
            private_key = "${file(var.private_key)}"
            host = "${self.ipv4_address}"
        }
    }
}

resource "digitalocean_floating_ip" "rabbitmq" {
  region = "${element(data.digitalocean_droplet_snapshot.heartbeat.regions.*, 1)}"
}

resource "digitalocean_volume" "drbd" {
  count                   = 2
  region                  = "lon1"
  name                    = "drbd${count.index}"
  size                    = 20
#   initial_filesystem_type = "ext4"
  description             = "DRBD Volume"
}

resource "digitalocean_volume_attachment" "drbd" {
  count = 2
  droplet_id = digitalocean_droplet.rabbitmq[count.index].id
  volume_id  = digitalocean_volume.drbd[count.index].id
}

data "template_file" "init_ansible_inventory" {
    template = "${file("ansible_inventory.tpl")}"
    vars = {
        primary = "${digitalocean_droplet.rabbitmq[0].ipv4_address}"
        secondary = "${digitalocean_droplet.rabbitmq[1].ipv4_address}"
        primary_droplet_id = "${digitalocean_droplet.rabbitmq[0].id}"
        secondary_droplet_id = "${digitalocean_droplet.rabbitmq[1].id}"
        floating_ip = "${digitalocean_floating_ip.rabbitmq.ip_address}"
        primary_name = "${digitalocean_droplet.rabbitmq[0].name}"
        secondary_name = "${digitalocean_droplet.rabbitmq[0].name}"
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

data "digitalocean_domain" "hackandpwned" {
    name = "hackandpwned.fr"
}

resource "digitalocean_record" "rabbitmq" {
    domain = data.digitalocean_domain.hackandpwned.name
    type = "A"
    name = "rabbit"
    value = digitalocean_floating_ip.rabbitmq.ip_address
}

output "fqdn" {
    value = digitalocean_record.rabbitmq.fqdn
}