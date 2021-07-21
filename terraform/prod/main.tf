// Раскомментировать при использовании terraform >=v1.0.0
//terraform {
//  required_providers {
//    yandex = {
//      source = "yandex-cloud/yandex"
//    }
//  }
//}

provider "yandex" {
  service_account_key_file = var.account_key_path
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  version                  = 0.35
}

module "app" {
  source          = "../modules/app"
  public_key_path = var.public_key_path
  app_disc_image  = var.app_disc_image
  subnet_id       = var.subnet_id
}

module "db" {
  source          = "../modules/db"
  public_key_path = var.public_key_path
  db_disc_image   = var.db_disc_image
  subnet_id       = var.subnet_id
}

resource "yandex_storage_bucket" "terraform" {
  access_key = "access-key"
  secret_key = "secret-key"
  bucket = "terraform-hw"
  force_destroy = true
}
