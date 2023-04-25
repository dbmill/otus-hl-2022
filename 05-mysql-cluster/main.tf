data "yandex_vpc_subnet" "default" {
  name = "default-${var.provider_zone}"
}
data "yandex_compute_image" "myimage" {
  family = "centos-stream-8"
}
data "local_file" "public_key" {
  filename = "${pathexpand("~/.ssh")}/${element(tolist(fileset(pathexpand("~/.ssh"), "id_*.pub")),0)}"
}
data "local_sensitive_file" "private_key" {
  filename = trimsuffix(data.local_file.public_key.filename, ".pub")
}

resource "yandex_compute_instance" "dbcluster" {
  count = var.dbcluster_size
  name     = "${var.dbhost_name}${count.index}"
  hostname = "${var.dbhost_name}${count.index + 1}"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.myimage.id
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.cloud_user}:${data.local_file.public_key.content}"
  }

# A hack to give sshd time to start
  connection {
    type = "ssh"
    host = self.network_interface.0.nat_ip_address
    user = var.cloud_user
    private_key = data.local_sensitive_file.private_key.content
  } 
  provisioner "remote-exec" {
    inline = ["date"]
  }
}

resource "yandex_compute_instance" "dbproxy" {
  name     = "dbproxy"
  hostname = "dbproxy"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.myimage.id
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.cloud_user}:${data.local_file.public_key.content}"
  }

# A hack to give sshd time to start
  connection {
    type = "ssh"
    host = self.network_interface.0.nat_ip_address
    user = var.cloud_user
    private_key = data.local_sensitive_file.private_key.content
  } 
  provisioner "remote-exec" {
    inline = ["date"]
  }
}

resource "yandex_compute_instance" "client" {
  name     = "client"
  hostname = "client"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.myimage.id
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.cloud_user}:${data.local_file.public_key.content}"
  }

# A hack to give sshd time to start
  connection {
    type = "ssh"
    host = self.network_interface.0.nat_ip_address
    user = var.cloud_user
    private_key = data.local_sensitive_file.private_key.content
  }
  provisioner "remote-exec" {
    inline = ["date"]
  }
}

resource "local_file" "inventory" {
  filename = "./hosts"
  content  = <<-EOF
  [dbcluster]
  %{for vm in yandex_compute_instance.dbcluster.* ~}${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  %{endfor ~}

  [dbproxies]
  %{for vm in yandex_compute_instance.dbproxy.* ~}${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  %{endfor ~}
  [clients]
  %{for vm in yandex_compute_instance.client.* ~}${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  %{endfor ~}
  EOF
  file_permission = "0644"
}

resource "local_file" "init_yml" {
  filename = "./init.yml"
  content = templatefile("init.yml.tftpl", {
    remote_user    = var.cloud_user,
    dbcluster_size = var.dbcluster_size,
    nodes          = yandex_compute_instance.dbcluster[*],
    pxc_repo_file  = var.pxc_repo_file,
    pxc_repo_name  = var.pxc_repo_name,
    mysql_passwd   = var.mysql_passwd,
    dbproxy        = yandex_compute_instance.dbproxy
	client         = yandex_compute_instance.client
  })
  file_permission = "0644"
}

resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.init_yml.filename}"
  }
}

output "dbcluster_private_ip" {
  value = yandex_compute_instance.dbcluster[*].network_interface.0.ip_address
}
output "dbproxy_private_ip" {
  value = yandex_compute_instance.dbproxy.network_interface.0.ip_address
}

output "dbcluster_public_ip" {
  value = yandex_compute_instance.dbcluster[*].network_interface.0.nat_ip_address
}
output "dbproxy_public_ip" {
  value = yandex_compute_instance.dbproxy.network_interface.0.nat_ip_address
}
output "ClientIP" {
  value = yandex_compute_instance.client.network_interface.0.nat_ip_address
}
