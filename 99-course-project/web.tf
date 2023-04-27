data "yandex_compute_image" "common" {
  family = "centos-stream-8"
}

resource "yandex_compute_instance" "haproxy" {
  count = 2
  name     = "haproxy${count.index + 1}"
  hostname = "haproxy${count.index + 1}"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.common.id
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
#    ip_address = cidrhost(yandex_vpc_subnet.default.v4_cidr_blocks[0], var.ipHaproxy+count.index)
  }

  metadata = {
    ssh-keys = "${var.cloud_user}:${data.local_file.public_key.content}"
  }

  # A hack to give sshd time to start
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = self.network_interface.0.ip_address
      user = var.cloud_user
      private_key = data.local_sensitive_file.private_key.content
      bastion_host = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
      bastion_user = var.bastion_user
    } 
    inline = ["date"]
  }
  # remove self from known_hosts
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^${self.hostname}\\W/d' ~/.ssh/known_hosts"
  }
}

resource "yandex_compute_instance" "nginx" {
  count = 2
  name     = "nginx${count.index + 1}"
  hostname = "nginx${count.index + 1}"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.common.id
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
  }

  metadata = {
    ssh-keys = "${var.cloud_user}:${data.local_file.public_key.content}"
  }

  # A hack to give sshd time to start
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = self.network_interface.0.ip_address
      user = var.cloud_user
      private_key = data.local_sensitive_file.private_key.content
      bastion_host = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
      bastion_user = var.bastion_user
    } 
    inline = ["date"]
  }
  # remove self from known_hosts
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^${self.hostname}\\W/d' ~/.ssh/known_hosts"
  }
}

resource "yandex_lb_target_group" "haproxy" {
  name = "haproxy"

  dynamic "target" {
    for_each = yandex_compute_instance.haproxy
    content {
      subnet_id = yandex_vpc_subnet.default.id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "web" {
  name = "web"
  listener {
    name = "http"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.haproxy.id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/fpm-ping"
      }
    }
  }
}

output "Project_URL" {
  value = "http://${tolist(tolist(yandex_lb_network_load_balancer.web.listener)[0].external_address_spec)[0].address}"
}