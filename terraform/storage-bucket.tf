provider "yandex" {
  service_account_key_file = var.account_key_path
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  version                  = 0.35
}

resource "yandex_storage_bucket" "terraform" {
  access_key    = var.s3_access_key
  secret_key    = var.s3_secret_key
  bucket        = "terraform-hw"
  force_destroy = true
}
