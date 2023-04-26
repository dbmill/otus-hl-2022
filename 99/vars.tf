data "local_file" "public_key" {
  filename = "${pathexpand("~/.ssh")}/${element(tolist(fileset(pathexpand("~/.ssh"), "id_*.pub")),0)}"
}
data "local_sensitive_file" "private_key" {
  filename = trimsuffix(data.local_file.public_key.filename, ".pub")
}

variable "bakdir" {
  type = string
  description = "Where a Wiki backup resides"
  default = "WIKI-BAK"
}
variable "provider_zone" {
  type = string
  default = "ru-central1-a"
}
variable "subNet" {
  type = string
  default = "10.1.1.0/24"
}
variable "ipBastion" {
  type = number
  default = 254
}
variable "bastion_user" {
  type = string
  default = "ubuntu"
}
variable "cloud_user" {
  type = string
  description = "It was 'centos' before 2022-11, and it is 'cloud-user' since 2022-11"
  default = "cloud-user"
}

variable "dbhost_name" {
  type = string
  default = "mysql"
}
variable "dbcluster_size" {
  type = number
  default = 3
}
variable "dbproxy_size" {
  type = number
  default = 2
}
variable "pxc_repo_file" {
  type = string
  default = "percona-pxc-80-release.repo"
}
variable "pxc_repo_name" {
  type = string
  default = "pxc-80-release-x86_64"
}
variable "mysql_user" {
  type = string
  default = "sbuser"
}
variable "mysql_passwd" {
  type = string
  default = "123"
}

variable "gluster_name" {
  type = string
  default = "gluster"
}
variable "gluster_size" {
  type = number
  default = 3
}

