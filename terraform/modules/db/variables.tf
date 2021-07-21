variable "db_disc_image" {
  description = "Disk image for reddit db"
  default     = "mongodb-base"
}
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
variable subnet_id {
  description = "Subnets for modules"
}
