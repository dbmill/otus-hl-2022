variable "provider_zone" {
  type = string
  default = "ru-central1-a"
}
variable "cloud_user" {
  type = string
  description = "It was 'centos' before 2022-11, and it is 'cloud-user' since 2022-11"
  default = "cloud-user"
}
variable "dbhost_name" {
  type = string
  default = "otus-db"
}
variable "dbcluster_size" {
  type = number
  default = 3
}
variable "pxc_repo_file" {
  type = string
  default = "percona-pxc-80-release.repo"
}
variable "pxc_repo_name" {
  type = string
  default = "pxc-80-release-x86_64"
}
variable "mysql_passwd" {
  type = string
  default = "Otus321$"
}
