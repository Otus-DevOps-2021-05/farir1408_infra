variable "cloud_id" {
  description = "Cloud"
}
variable "folder_id" {
  description = "Folder"
}
variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}
variable "image_id" {
  description = "Image"
}
variable "subnet_id" {
  description = "Subnet"
}
variable "account_key_path" {
  description = "Path to the service account key file used for cloud access"
}
variable "app_disc_image" {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}
variable "db_disc_image" {
  description = "Disk image for reddit db"
  default     = "mongodb-base"
}
variable "s3_access_key" {
  description = "Object storage access key"
}
variable "s3_secret_key" {
  description = "Object storage secret key"
}
