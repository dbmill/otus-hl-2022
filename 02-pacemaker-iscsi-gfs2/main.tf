terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

data "yandex_vpc_network" "default" {
  name = "default"
}
data "yandex_compute_image" "myimage" {
# yc compute image list --folder-id standard-images
  family = "centos-7"
}
data "local_file" "public_key" {
  filename = "${pathexpand("~/.ssh")}/${element(tolist(fileset(pathexpand("~/.ssh"), "id_*.pub")),0)}"
}
data "local_sensitive_file" "private_key" {
  filename = trimsuffix(data.local_file.public_key.filename, ".pub")
}

variable "cloud_user" {
  type = string
  description = "It was 'centos' before 2022-11, and it is 'cloud-user' since 2022-11"
}
variable "cluster_name" {
  type = string
  description = "A name of a cluster to create"
}
variable "cluster" {
  type = string
  description = "A stem for cluster nodes"
}
variable "cluster_size" {
  type = number
}
variable "iqn_base" {
  type = string
  default = "iqn.2022-12.ru.otus"
}
variable "vg_name" {
  type = string
  default = "vg_cluster"
}
variable "lv_name" {
  type = string
  default = "lv_cluster"
}
variable "fs_name" {
  type = string
  default = "fs_cluster"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = data.yandex_vpc_network.default.network_id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-a"
  network_id     = data.yandex_vpc_network.default.network_id
  v4_cidr_blocks = ["192.168.11.0/24"]
}

resource "yandex_compute_disk" "gfs2" {
  name = "gfs2-disk"
  size = 50
  type = "network-hdd"
}

resource "yandex_compute_instance" "iscsi" {
  name = "iscsi"
  hostname = "iscsi"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      name = "boot-disk-iscsi"
      image_id = data.yandex_compute_image.myimage.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
  }

  secondary_disk {
    disk_id = yandex_compute_disk.gfs2.id
    device_name = "gfs2"
  }

  metadata = {
    ssh-keys = "${var.cloud_user}:${data.local_file.public_key.content}"
  }

# A hack to give sshd time to wake up
  connection {
    type = "ssh"
    host = self.network_interface.0.nat_ip_address
    user = var.cloud_user
    private_key = data.local_sensitive_file.private_key.content
    timeout = "15m"
  } 
  provisioner "remote-exec" {
    inline = ["date"]
  }
}

resource "yandex_compute_instance" "cluster" {
  count = var.cluster_size
  name     = "${var.cluster}${count.index + 1}"
  hostname = "${var.cluster}${count.index + 1}"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      name = "boot-disk-${var.cluster}${count.index + 1}"
      image_id = data.yandex_compute_image.myimage.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
  }

  metadata = {
    ssh-keys = "${var.cloud_user}:${data.local_file.public_key.content}"
  }

# A hack to give sshd time to wake up
  connection {
    type = "ssh"
    host = self.network_interface.0.nat_ip_address
    user = var.cloud_user
    private_key = data.local_sensitive_file.private_key.content
    timeout = "15m"
  } 
  provisioner "remote-exec" {
    inline = ["date"]
  }
}

resource "local_file" "inventory" {
  filename = "./hosts"
  file_permission = "0644"
  content  = <<EOT
[iscsi_group]
%{ for vm in yandex_compute_instance.iscsi.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }
[cluster]
%{ for vm in yandex_compute_instance.cluster.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
EOT
}

resource "local_file" "init_yml" {
  filename = "./init.yml"
  file_permission = "0644"
  content = templatefile("init.yml.tmpl", {
    remote_user=var.cloud_user,
    cluster_name=var.cluster_name,
    cluster_size=var.cluster_size,
    iscsi=yandex_compute_instance.iscsi,
    nodes=yandex_compute_instance.cluster[*],
    iqn_base=var.iqn_base,
    vg_name=var.vg_name,
    lv_name=var.lv_name,
    fs_name=var.fs_name
  })
}

resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.init_yml.filename}"
  }
}

output "private_ip_address_iscsi" {
  value = yandex_compute_instance.iscsi[*].network_interface.*.ip_address
}
output "private_ip_address_cluster" {
  value = yandex_compute_instance.cluster[*].network_interface.*.ip_address
}
output "public_ip_address_iscsi" {
  value = yandex_compute_instance.iscsi[*].network_interface.0.nat_ip_address
}
output "public_ip_address_cluster" {
  value = yandex_compute_instance.cluster[*].network_interface.0.nat_ip_address
}
