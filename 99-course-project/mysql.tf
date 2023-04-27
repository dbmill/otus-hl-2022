resource "yandex_compute_instance" "dbcluster" {
  count = var.dbcluster_size
  name     = "${var.dbhost_name}${count.index + 1}"
  hostname = "${var.dbhost_name}${count.index + 1}"

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
#    ip_address = cidrhost(yandex_vpc_subnet.default.v4_cidr_blocks[0], var.ipDbcluster+count.index)
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
  # remove PXC cert
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${self.hostname}"
  }
}

resource "yandex_compute_instance" "dbproxy" {
  count = var.dbproxy_size
  name     = "dbproxy${count.index + 1}"
  hostname = "dbproxy${count.index + 1}"

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
#    ip_address = cidrhost(yandex_vpc_subnet.default.v4_cidr_blocks[0], var.ipProxySQL+count.index)
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

resource "yandex_lb_target_group" "dbproxy" {
  name = "dbproxy"

  dynamic "target" {
    for_each = yandex_compute_instance.dbproxy
    content {
      subnet_id = yandex_vpc_subnet.default.id
      address   = target.value.network_interface.0.ip_address
	  }
  }
}

resource "yandex_lb_network_load_balancer" "sql" {
  name = "sql"
  type = "internal"
  listener {
    name = "proxysql"
    port = 3306
	  target_port = 6033
    internal_address_spec {
      subnet_id = yandex_vpc_subnet.default.id
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.dbproxy.id
    healthcheck {
      name = "proxysql"
      tcp_options {
        port = 6033
      }
    }
  }
}
