variable "do_token" {}

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
    name = "rabbitmq-${count.index}"
    region = "lon1"
    size = "s-1vcpu-1gb"
    ssh_keys = [data.digitalocean_ssh_key.ssh_key.id]
}

output "rabbitmq1_ip_address" {
    value = digitalocean_droplet.rabbitmq[0].ipv4_address
}

output "rabbitmq2_ip_address" {
    value = digitalocean_droplet.rabbitmq[1].ipv4_address
}