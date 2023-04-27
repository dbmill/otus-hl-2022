terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = var.provider_zone
}

data "yandex_compute_image" "bastion_image" {
  family = "nat-instance-ubuntu"
}

resource "yandex_vpc_network" "default" {
  name = "otus-net"
}
resource "yandex_vpc_route_table" "route_private" {
  network_id = yandex_vpc_network.default.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = cidrhost(var.subNet, var.ipBastion)
  }
}
resource "yandex_vpc_subnet" "default" {
  name           = "otus-subnet"
  network_id     = yandex_vpc_network.default.id
  zone           = var.provider_zone
  v4_cidr_blocks = [var.subNet]
  route_table_id = yandex_vpc_route_table.route_private.id
}

resource "yandex_compute_instance" "bastion" {
  name     = "bastion"
  hostname = "bastion"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.bastion_image.id
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.default.id
    ip_address = cidrhost(yandex_vpc_subnet.default.v4_cidr_blocks[0], var.ipBastion)
    nat        = true
  }

  metadata = {
    ssh-keys = "${var.bastion_user}:${data.local_file.public_key.content}"
  }

  # A hack to give sshd time to start
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = self.network_interface.0.nat_ip_address
      user = var.bastion_user
      private_key = data.local_sensitive_file.private_key.content
    } 
    inline = ["date"]
  }
  # add self to /etc/hosts
  provisioner "local-exec" {
    command = "sudo sed -i 'a${self.network_interface.0.nat_ip_address} ${self.hostname}' /etc/hosts"
  }
  # remove self from /etc/hosts
  provisioner "local-exec" {
    when    = destroy
    command = "sudo sed -i '/^${self.network_interface.0.nat_ip_address} ${self.hostname}$/d' /etc/hosts"
  }
  # remove self from known_hosts
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^${self.hostname}\\W/d' ~/.ssh/known_hosts"
  }
}

output "BastionIP" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}