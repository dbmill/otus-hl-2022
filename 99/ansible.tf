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
  })
  file_permission = "0644"
}

resource "local_file" "haproxy_cfg" {
  filename = "./haproxy.cfg"
  content = templatefile("haproxy.cfg.tftpl", {nginx=yandex_compute_instance.nginx})
  file_permission = "0644"
}
  
resource "local_file" "playbook_yml" {
  filename = "./playbook.yml"
  content = templatefile("playbook.yml.tftpl", {
    bastion   = yandex_compute_instance.bastion
    haproxy   = yandex_compute_instance.haproxy
	haproxylb = tolist(tolist(yandex_lb_network_load_balancer.web.listener)[0].external_address_spec)[0].address
    nginx     = yandex_compute_instance.nginx
    dbcluster = yandex_compute_instance.dbcluster
    dbproxy   = yandex_compute_instance.dbproxy
	dbproxylb = tolist(tolist(yandex_lb_network_load_balancer.sql.listener)[0].internal_address_spec)[0].address
  })
  file_permission = "0644"
}

resource "null_resource" "ansible_web" {
  depends_on = [local_file.inventory, local_file.haproxy_cfg]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.playbook_yml.filename}"
#    command = "echo ansible 1"
  }
}

resource "local_file" "mysql_yml" {
  filename = "./mysql.yml"
  content = templatefile("mysql.yml.tftpl", {
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

resource "null_resource" "ansible_db" {
  depends_on = [null_resource.ansible_web]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.mysql_yml.filename}"
#    command = "echo ansible 2"
  }
}

resource "local_file" "local_settings" {
  filename = "1941-copy/LocalSettings.php"
  content = templatefile("1941-copy/LocalSettings.php.tftpl", {
	haproxylb = tolist(tolist(yandex_lb_network_load_balancer.web.listener)[0].external_address_spec)[0].address
	mysql_user	   = var.mysql_user
    mysql_passwd   = var.mysql_passwd
  })
  file_permission = "0644"
}

resource "null_resource" "ansible3" {
  depends_on = [null_resource.ansible_db, local_file.local_settings]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ./3deploy.yml"
#    command = "echo ansible 2"
  }
}
