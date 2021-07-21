resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  labels = {
    tags = "reddit-app"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disc_image
    }
  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }
}
