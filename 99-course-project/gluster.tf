resource "yandex_compute_disk" "gluster" {
  count = var.gluster_size
  name  = "${var.gluster_name}${count.index + 1}"
  size = 10
  type = "network-hdd"
}

resource "yandex_compute_instance" "gluster" {
  count = var.gluster_size
  name     = "${var.gluster_name}${count.index + 1}"
  hostname = "${var.gluster_name}${count.index + 1}"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.common.id
    }
  }
  secondary_disk {
    disk_id = yandex_compute_disk.gluster[count.index].id
    device_name = "glusterfs"
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
#    ip_address = cidrhost(yandex_vpc_subnet.default.v4_cidr_blocks[0], var.ipGluster+count.index)
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