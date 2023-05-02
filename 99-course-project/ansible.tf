resource "local_file" "inventory" {
  filename = "./hosts"
  content  = templatefile("hosts.tftpl", {
    bastion      = yandex_compute_instance.bastion
    bastion_user = var.bastion_user
    haproxy      = yandex_compute_instance.haproxy
    nginx        = yandex_compute_instance.nginx
    dbcluster    = yandex_compute_instance.dbcluster
    dbproxy      = yandex_compute_instance.dbproxy
    gluster      = yandex_compute_instance.gluster
    cloud_user   = var.cloud_user
	bakdir       = var.bakdir
  })
  file_permission = "0644"
}

resource "null_resource" "ansible_0" {
  provisioner "local-exec" {
    command = "ansible-playbook ./0download.yml"
  }
}

resource "local_file" "common_yml" {
  filename = "./1common.yml"
  content = templatefile("1common.yml.tftpl", {
	dbproxylb = tolist(tolist(yandex_lb_network_load_balancer.sql.listener)[0].internal_address_spec)[0].address
  })
  file_permission = "0644"
}

resource "null_resource" "ansible_1" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.common_yml.filename}"
#    command = "echo ansible 1"
  }
}

resource "local_file" "gluster_yml" {
  filename = "./2gluster.yml"
  content = templatefile("2gluster.yml.tftpl", {
    gluster   = yandex_compute_instance.gluster
  })
  file_permission = "0644"
}

resource "null_resource" "ansible_2" {
  depends_on = [null_resource.ansible_1]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.gluster_yml.filename}"
#    command = "echo ansible 2"
  }
}

resource "local_file" "mysql_yml" {
  filename = "./3mysql.yml"
  content = templatefile("3mysql.yml.tftpl", {
    nginx          = yandex_compute_instance.nginx
    dbcluster      = yandex_compute_instance.dbcluster
    pxc_repo_file  = var.pxc_repo_file
    pxc_repo_name  = var.pxc_repo_name
	mysql_user	   = var.mysql_user
    mysql_passwd   = var.mysql_passwd
    dbproxy        = yandex_compute_instance.dbproxy
  })
  file_permission = "0644"
}

resource "null_resource" "ansible_3" {
  depends_on = [null_resource.ansible_2]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.mysql_yml.filename}"
#    command = "echo ansible 3"
  }
}

resource "local_file" "haproxy_cfg" {
  filename = "./haproxy.cfg"
  content = templatefile("haproxy.cfg.tftpl", {nginx=yandex_compute_instance.nginx})
  file_permission = "0644"
}

resource "local_file" "web_yml" {
  filename = "./4web.yml"
  content = templatefile("4web.yml.tftpl", {})
  file_permission = "0644"
}

resource "null_resource" "ansible_4" {
  depends_on = [
    null_resource.ansible_0,
    null_resource.ansible_3,
    local_file.haproxy_cfg
  ]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.web_yml.filename}"
#    command = "echo ansible 4"
  }
}

resource "local_file" "local_settings" {
  filename = "${var.bakdir}/LocalSettings.php"
  content = templatefile("${var.bakdir}/LocalSettings.php.tftpl", {
	haproxylb = tolist(tolist(yandex_lb_network_load_balancer.web.listener)[0].external_address_spec)[0].address
	mysql_user	 = var.mysql_user
    mysql_passwd = var.mysql_passwd
  })
  file_permission = "0644"
}

resource "null_resource" "ansible_9" {
  depends_on = [null_resource.ansible_4, local_file.local_settings]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ./9deploy.yml"
#    command = "echo ansible 9"
  }
}