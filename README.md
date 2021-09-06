# farir1408_infra
farir1408 Infra repository

## HW-03 (Lecture 5)
#### branch: `cloud-bastion`
- [X] Подключиться к bastion.
- [X] Подключиться к someinternalhost в одну команду.
- [X] Дополнительное задание: подключиться к someinternalhost с помощью команды `ssh someinternalhost`
- [X] Создать VPN-сервер для серверов Yandex.Cloud

<details><summary>Решение</summary>

* Подключение к bastion.
```editorconfig
bastion_IP = 84.201.128.185
someinternalhost_IP = 10.128.0.31
```

* Упрощаем подключение к bastion:
  В ~/.ssh/config внести:
```editorconfig
Host bastion
  Hostname 84.201.128.185
  User appuser
  IdentityFile ~/.ssh/otus_devops
```

#### В результате к bastion host можно подключиться с помощью команды: `ssh bastion`

* Подключение к someinternalhost в одну команду - `ssh someinternalhost`
  В ~/.ssh/config добавить:
```editorconfig
Host someinternalhost
  Hostname 10.128.0.31
  User appuser
  ProxyCommand ssh -W %h:%p bastion
  IdentityFile ~/.ssh/otus_devops
```

#### В результате к someinternalhost host можно подключиться с помощью команды: `ssh someinternalhost`

* Создать VPN-сервер для серверов Yandex.Cloud

Установить утилиту pritunl:
```editorconfig
cat <<EOF> setupvpn.sh
#!/bin/bash
sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list << EOF
deb https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse
EOF
sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb http://repo.pritunl.com/stable/apt bionic main
EOF
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
sudo apt-get update && sudo apt-get install iptables
sudo apt-get --assume-yes install pritunl mongodb-server
sudo systemctl start pritunl mongodb
sudo systemctl enable pritunl mongodb
EOF
```

Запустить скрипт:
```editorconfig
sudo bash setupvpn.sh
```

Открыть в браузере веб-интерфейс pritunl `https://<адрес bastion VM>/setup`

Сгенерировать ключ для доступа к веб-интерфейсу:
```editorconfig
sudo pritunl setup-key
```

Сгенерировать пользователя для доступа к веб-интерфейсу:
```editorconfig
sudo pritunl default-password
```

Создать пользователя:
```editorconfig
username: test
PIN: 6214157507237678334670591556762
```

Настроить сервер и сохранить конфигурацию для подключения vpn.

</details>

## HW-04 (Lecture 6)
#### branch: `cloud-testapp`
- [X] Установить yc.
- [X] Установить ruby используя install_ruby.sh.
- [X] Установить mongodb используя install_mongodb.sh
- [X] Установить приложение reddit используя deploy.sh
- [X] Доп. задание: написать startup script, который будет запускаться при создании инстанса.

<details><summary>Решение</summary>

* Для установки [yandex cli](https://cloud.yandex.ru/docs/cli/operations/install-cli) выполнить команду:
```editorconfig
curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

* Для дальнейшей работы необходимо [создать профиль](https://cloud.yandex.ru/docs/cli/operations/profile/profile-create).

* Проверить настройки профиля:
```editorconfig
yc config profile get <имя профиля>
```

#### В результате будет установлена утилита yc

* Создать виртуальную машину используя yandex cli (yc)
  В терминале выполнить команду:
```editorconfig
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/otus_devops.pub
```

* Список команд для работы:
```editorconfig
yc compute instance list
yc compute instance create
yc compute instance delete
yc compute instance get
yc compute instance start/stop
```

#### В результате будет создана виртуальная машина с ubuntu16.04 `ssh yc-user@217.28.228.11`

* Подключение к созданной виртуальной машине.
```editorconfig
testapp_IP = 217.28.228.11
testapp_port = 9292
```

* Установить ruby, содержимое файла install_ruby.sh:
```editorconfig
#!/bin/bash

sudo apt update && sudo apt install -y ruby-full ruby-bundler build-essential
echo "ruby version is:"
ruby -v
echo "bundler version is:"
bundler -v
```

* Установить mongodb, содержимое файла install_mongodb.sh:
```editorconfig
#!/bin/bash

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-get --assume-yes update
sudo apt-get --assume-yes install mongodb-org

sudo systemctl start mongod
sudo systemctl enable mongod

echo "MongoDB status is:"
sudo systemctl status mongod
```

* Установить приложение reddit, содержимое файла deploy.sh:
```editorconfig
#!/bin/bash

sudo apt-get install git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install

puma -d
```

* Все скрипты перед запуском необходимо сделать исполняемыми:
```editorconfig
$ sudo chmod +x *.sh
$ sudo bash install_ruby.sh
$ sudo bash install_mongodb.sh
$ sudo bash deploy.sh
```

#### В результате по адресу 217.28.228.11:9292 будет запущен веб-сервис reddit.

* написать startup script, который будет запускаться при создании инстанса.

Содержимое файла `metadata.yaml`

```editorconfig
#cloud-config
users:
  - default
  - name: yc-user
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZkfDN3hmAb3nIx0JHuMNBtVBa7YTO5bY7NavHTpUX0uP5/ncTGvcBKhPs+ftI0yvOGgj7oALRasKMf8E4A7JnyAKqUpB0hJcTkMtQnHDHntuvgUo7LqCol5r7XBt6BfIHfVToRpJb65qGo25jHqYYa1VvgkGL0c/GwqvGO7k/TvRdVznT55sDvh7X63pe4z3U8QDI4aiwon20FL+FktdJf1se/kJJxSzUcG+k7b/kD64Jw2JTgK8Vy2K+CDDfnYwO8Wkf00GKsfgsCUHUZSDb+sC54ufR7ihzBbBIRZ2WoUXGLiGrso+z2K/QJtJQ5KijnFT/zdLu8tiupK07RPWD ovvenger@MSK-C02DC08BMD6R.local

runcmd:
  - wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
  - echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

  - sudo apt-get install -y apt-transport-https ca-certificates
  - sudo apt-get --assume-yes update

  - sudo apt install -y ruby-full ruby-bundler build-essential mongodb-org git
  - sudo systemctl start mongod
  - sudo systemctl enable mongod

  - git clone -b monolith https://github.com/express42/reddit.git
  - cd reddit && bundle install
  - puma -d
```

* Создать виртуальную машину, используя файл metadata.yaml:
```editorconfig
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=metadata.yaml
```

</details>

## HW-05 (Lecture 7)
#### branch: `packer-base`
- [X] Установить packer.
- [X] Создать пользовательский образ с установленными зависимостями.
- [X] Запустить виртуальную машину из созданного образа и установить reddit app.
- [X] Параметризовать build файл packer.
- [X] Дополнительное задание: Построить bake-образ
- [ ] Дополнительное задание: Автоматизировать создание VM

<details><summary>Решение</summary>

#### Установить packer

* Установить [packer](https://www.packer.io/downloads)
```editorconfig
packer -v
1.7.3
```

* Получить folder-id с помощью команды: `yc config list`

* Создать сервисный аккаунт
```editorconfig
SVC_ACCT="<придумайте имя>"
FOLDER_ID="<замените на собственный>"
yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
```

* Выдать права сервисному аккаунту
```editorconfig
ACCT_ID=$(yc iam service-account get $SVC_ACCT | \
    grep ^id | \
    awk '{print $2}')
yc resource-manager folder add-access-binding --id $FOLDER_ID \
    --role editor \
    --service-account-id $ACCT_ID
```

* Создать key file для сервисного аккаунта
```editorconfig
yc iam key create --service-account-id $ACCT_ID --output <вставьте свой путь>/key.json
```

#### Создать пользовательский образ с установленными зависимостями

* Создать build файл для packer
```json
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "key.json.example",
            "folder_id": "some-folder-id",
	        "zone": "ru-central1-a",
	        "subnet_id": "some-subnet-id",
	        "use_ipv4_nat": true,
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

* Выполнить проверку синтаксиса
```editorconfig
packer validate ./ubuntu.json
```

* Собрать образ с помощью packer
```editorconfig
packer build ./ubuntu.json
```

#### Запустить виртуальную машину из созданного образа и установить reddit app

* Получить id созданного образа:
```editorconfig
yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| fd8jdb89uu7ord4urmvb | reddit-base-1625578780 | reddit-base | f2el9g14ih63bjul3ed3 | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```

* Создать VM из образа:
```editorconfig
yc compute instance create \
  --name reddit-packer-app \
  --hostname reddit-packer-app \
  --memory=4 \
  --create-boot-disk image-id=fd8jdb89uu7ord4urmvb,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/otus_devops.pub
```

* Запустить reddit app, выполнить следующие команды в консоли VM
```editorconfig
sudo apt-get update
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```

* Проверить запущенное приложение в браузере
`http://vm-publick-ip:9292/`

#### Параметризовать build файл packer

* Создать файл с переменными variables.json
```json
{
    "account_key_path": "key.json.example",
    "folder_id": "some-folder-id",
    "image": "ubuntu-1604-lts",
    "subnet_id": "some-subnet-id"
}
```

* Добавить переменные в packer build файл
```json
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `account_key_path`}}",
            "folder_id": "{{user `folder_id`}}",
	        "zone": "ru-central1-a",
	        "subnet_id": "{{user `subnet_id`}}",
	        "use_ipv4_nat": true,
            "source_image_family": "{{user `image`}}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

#### Построить bake-образ

Содержимое файла immutable.json
```json
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `account_key_path`}}",
            "folder_id": "{{user `folder_id`}}",
	        "zone": "ru-central1-a",
	        "subnet_id": "{{user `subnet_id`}}",
	        "use_ipv4_nat": true,
            "source_image_family": "{{user `image`}}",
            "image_name": "reddit-full-{{timestamp}}",
            "image_family": "reddit-full",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "file",
            "source": "files/reddit.service",
            "destination": "/tmp/reddit.service"
        },
        {
            "type": "shell",
            "inline": [
                "sudo mv /tmp/reddit.service /etc/systemd/system/reddit.service",
                "sudo apt-get install -y git",
                "git clone -b monolith https://github.com/express42/reddit.git",
                "cd reddit && bundle install",
                "sudo systemctl daemon-reload && sudo systemctl start reddit && sudo systemctl enable reddit"
            ]
        }
    ]
}
```

</details>

## HW-06 (Lecture 8)
#### branch: `terraform-1`
- [X] Установить terraform.
- [X] Создать VM из исходного образа.
- [X] Автоматически запускать приложение в новой VM.
- [X] Параметризация конфиг файла.
- [X] Доп. задание: создать балансировщик нагрузки.
- [X] Доп. задание: создать второй инстанс приложения.
- [X] Доп. задание: использовать автоматическое масштабирование инстансов через count.

<details><summary>Решение</summary>

#### Установить terraform
* Установить [terraform](https://www.terraform.io/) используя [инструкцию](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started#install-terraform):
```editorconfig
terraform -v
Terraform v1.0.2
```

#### Создать VM из исходного образа.

* Создать сервисный аккаунт для terraform.

* Определить provider
```terraform
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  service_account_key_file = "/key.json"
  cloud_id                 = "cloud_id"
  folder_id                = "folder_id"
  zone                     = "zone"
}
```

Для получения `cloud_id`, `folder_id` использовать команду: `yc config list`

* Загрузить модуль провайдера:
```editorconfig
terraform init
```
В результате будет скачать провайдер yandex. Вывод команды `terraform -v` станет таким:
```editorconfig
Terraform v1.0.2
on darwin_amd64
+ provider registry.terraform.io/yandex-cloud/yandex v0.61.0
```

* Добавить ресурсы для VM
```terraform
resource "yandex_compute_instance" "app" {
  name = "reddit-app-${count.index}"

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашнем задании
      image_id = "image"
    }
  }
  network_interface {
    subnet_id = "subnet"
    nat       = true
  }
  resources {
    cores  = 2
    memory = 2
  }
}
```
Чтобы увидеть план изменений использовать команду: `terraform plan`. Знак "+" перед наименованием ресурса означает, что ресурс
будет добавлен. Далее приведены атрибуты этого ресурса. `known after apply` означает,
что данные атрибуты еще не известны terraform'у и их значения будут получены во время создания ресурса.

Для применения изменений использовать команду `terraform apply -auto-approve`. Результатом выполнения команды также будет создание файла terraform.tfstate в директории terraform.
Terraform хранит в этом файле состояние управляемых им ресурсов. Загляните в этот файл и найдите внешний IP адрес
созданного инстанса.

* Узнать публичный адрес созданной виртуальной машины

Команда `terraform show` отображает текущее состояние ресурсов в облаке. `terraform show | grep nat_ip_address` выведет публичный ip адрес созданной VM.
Однако такой способ усложняется когда в облаке много VM.

Для получения таких значений лучше использовать output. В файле outputs.tf прописать следующее содержимое:
```terraform
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```
Используем команду `terraform refresh` для того, чтобы переменные проинициализировалсь
Теперь команда `terraform output` выведет список переменных объявленных в этом файле.

* Подключение к VM по ssh

Для подключения необходимо в VM добавить публичный ключ. В блоке описания ресурса добавить:
```terraform
metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/otus_devops.pub")}"
}
```

#### Автоматически запускать приложение в новой VM

Provisioners в terraform вызываются в момент создания/удаления ресурса и позволяют выполнять команды на удаленной
или локальной машине. Их используют для запуска инструментов управления конфигурацией или начальной настройки системы.

* Определить провиженеры в ресурсе
```terraform
provisioner "file" {
  source      = "files/puma.service"
  destination = "/tmp/puma.service"
}
provisioner "remote-exec" {
  script = "files/deploy.sh"
}
```
`file` необходим для копирования Unit файла сервиса. `remote-exec` запускает скрипт установки приложения.

* Определить параметры для подключения провиженеров к VM.
```terraform
connection {
  type  = "ssh"
  host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user  = "ubuntu"
  agent = false
  # путь до приватного ключа
  private_key = file("~/.ssh/otus_devops")
}
```

После изменений конфига необходимо пересоздать ресурс. Можно воспользоваться командой `taint` чтобы пометить ресурс, который необходимо пересоздать.
```editorconfig
terraform taint yandex_compute_instance.app
terraform plan
terraform apply
```

Теперь в браузере по адресу `http://external_ip_address_app:9292/` будет доступна стартовая страница приложения.

#### Использовать переменные для параметризации конфиг файла.

* Создать файл с описанием переменных `variables.tf`
```terraform
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
```

* Создать файл со значениями переменных `terraform.tfvars`
```terraform
cloud_id         = "cloud_id"
folder_id        = "folder_id"
public_key_path  = "~/.ssh/otus_devops.pub"
private_key_path = "~/.ssh/otus_devops"
image_id         = "image"
subnet_id        = "subnet"
account_key_path = "terraform_key.json"
```

* Использовать переменные в конфигурационном файле

Пример на основе описания провайдера
```terraform
provider "yandex" {
  service_account_key_file = var.account_key_path
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
```

#### Доп. задание: создать балансировщик нагрузки.

Подробнее про балансировщик нагрузки в yandex облаке [тут](https://cloud.yandex.ru/docs/network-load-balancer/concepts/)

* Создать конфигурационный файл для балансировщика `lb.tf`

* Создать целевую группу
```terraform
resource "yandex_lb_target_group" "reddit_app_target_group" {
  name = "reddit-app-group"
  folder_id = var.folder_id
  region_id = "ru-central1"

  target {
    subnet_id = var.subnet_id
    address = yandex_compute_instance.app.network_interface.0.ip_address
  }
}
```

* Создать ресурс балансировщик
```terraform
resource "yandex_lb_network_load_balancer" "reddit_lb" {
  name = "reddit-app-lb"
  folder_id = var.folder_id

  listener {
    name = "reddit-listener"
    port = 80
    target_port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.reddit_app_target_group.id

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 9292
      }
    }
  }
}
```

* Добавить адрес балансировщик в outputs
```terraform
output "external_id_address_load_balancer" {
  value = yandex_lb_network_load_balancer.reddit_lb.listener.*.external_address_spec[0].*.address
}
```

После создания новых ресурсов приложением будет доступно по адресу `http://external_id_address_load_balancer/`
однако при недоступности инстанса `reddit-app`, приложением не будет функционировать.

#### Доп. задание: создать второй инстанс приложения

* Создать второй инстанс приложения
```terraform
resource "yandex_compute_instance" "app2" {
  name = "reddit-app2"
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашнем задании
      image_id = var.image_id
    }
  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }
  resources {
    cores  = 2
    memory = 2
  }

  connection {
    type  = "ssh"
    host  = yandex_compute_instance.app2.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}
```

* Добавить инстанс в группу балансировщика
```terraform
target {
  subnet_id = var.subnet_id
  address = yandex_compute_instance.app2.network_interface.0.ip_address
}
```

После создания новых ресурсов приложением будет доступно по адресу `http://external_id_address_load_balancer/`
При недоступности инстанса с приложением `reddit-app` запросы будут обрабатываться вторым инстансом `reddit-app2`

Плюсы данного решения:
* Отказоустойчивость, если недоступен один из инстансов, приложение продолжает работать

Минусы анного решения:
* Дублирование кода для создания нового инстанса
* БД (mongodb) не масштабируется, у каждого приложения своя копия бд.

#### Доп. задание: использовать автоматическое масштабирование инстансов через count

* Автоматически масштабировать количество инстансов приложения используя `count`
```terraform
resource "yandex_compute_instance" "app" {
  name = "reddit-app-${count.index}"
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  count = 2

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашнем задании
      image_id = var.image_id
    }
  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }
  resources {
    cores  = 2
    memory = 2
  }

  connection {
    type  = "ssh"
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}
```

* Автоматически добавлять инстансы в группу
```terraform
resource "yandex_lb_target_group" "reddit_app_target_group" {
  name = "reddit-app-group"
  folder_id = var.folder_id
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address = target.value
    }
  }
}
```

* В outputs выводить адреса всех созданных инстансов
```terraform
output "external_ip_address_app" {
  value = yandex_compute_instance.app[*].network_interface.0.nat_ip_address
}
```

Плюсы данного решения:
* Отказоустойчивость, если недоступен один из инстансов, приложение продолжает работать
* Автоматическое масштабирование, создание копий инстансов по шаблону

Минусы анного решения:
* БД (mongodb) не масштабируется, у каждого приложения своя копия бд.

</details>


## HW-07 (Lecture 9)
#### branch: `terraform-2`
- [X] Создать сеть и подсеть.
- [X] Структуризировать ресурсы.
- [X] Разбить конфигурацию на модули.
- [X] Создать prod и stage конфигурации.
- [X] Доп. задание: настроить хранение стейт на удалённом бекенде.
- [ ] Доп. задание: настроить запуск приложения при инициализации инстансов.

<details><summary>Решение</summary>

#### Создать сеть и подсеть

* В файле `main.tf` описать 2 ресурса: сеть и подсеть
```terraform
resource "yandex_vpc_network" "app-network" {
  name = "app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name = "app-subnet"
  zone = var.zone
  network_id = yandex_vpc_network.app-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```

После применения изменений будет созданы 3 ресурса, VM, сеть и подсеть. Сеть и подсеть будут созданы друг за другом
так как присутствует зависимость на `app-network.id`. Чтобы сделать зависимость VM от ресурса подсеть
необходимо явно указать это. Ссылку в одном ресурсе на атрибуты другого тераформ
понимает как зависимость одного ресурса от другого. Это влияет
на очередность создания и удаления ресурсов при применении
изменений.

```terraform
...
network_interface {
  subnet_id = yandex_vpc_subnet.app-subnet.id
  nat = true
}
...
```

#### Структуризировать ресурсы

* Создать образы для приложения и бд

Для создания 2х VM с приложением и базой данных, необходимо с помощью packer создать 2 новых образа.
В образе с приложением должен быть установлен ruby, в образе с базой данных необходимо установить и запустить mongod.

* Создать две VM

app.tf
```terraform
resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  labels = {
    tags = "reddit-app"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  resources {
    cores = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }
}
```

db.tf
```terraform
resource "yandex_compute_instance" "db" {
  name = "reddit-db"
  labels = {
    tags = "reddit-db"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }
}
```

variables.tf
```terraform
...
variable "app_disc_image" {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}
variable "db_disc_image" {
  description = "Disk image for reddit db"
  default = "mongodb-base"
}
...
```

* Создать конфигурацию для сети

vpc.tf
```terraform
resource "yandex_vpc_network" "app-network" {
  name = "app-network"
}
resource "yandex_vpc_subnet" "app-subnet" {
  name = "app-subnet"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.app-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```

* Отедактировать main и outputs

main.tf
```terraform
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  zone = var.zone
}
```

outputs.tf
```terraform
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```

#### Разбить конфигурацию на модули

* Создать модуль app

Содержимое директории с модулем:
```editorconfig
modules/app
├── docs.md
├── main.tf
├── outputs.tf
└── variables.tf
```

Содержимое файла main.tf
```terraform
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
```

Содержимое файла variables.tf
```terraform
variable "app_disc_image" {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
variable subnet_id {
  description = "Subnets for modules"
}
```

Содержимое файла outputs.tf
```terraform
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

Для автоматической генерации документации использовать утилиту [terraform-docs](https://github.com/terraform-docs/terraform-docs)

* Отредактировать файл main.tf

Содержимое файла main.tf с использованием модулей
```terraform
provider "yandex" {
  service_account_key_file = var.account_key_path
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  version                  = 0.35
}

module "app" {
  source = "./modules/app"
  public_key_path = var.public_key_path
  app_disc_image = var.app_disc_image
  subnet_id = var.subnet_id
}

module "db" {
  source = "./modules/db"
  public_key_path = var.public_key_path
  db_disc_image = var.db_disc_image
  subnet_id = var.subnet_id
}
```

Для начала работы с модулями их нужно загрузить из указанного источника с помощью команды: `terraform get`

* Отредактировать файл outputs.tf для получения значений из модулей
```terraform
output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}
```

Основную задачу, которую решают модули - это увеличивают
переиспользуемость кода и помогают нам следовать принципу DRY.
Инфраструктуру, которую мы описали в модулях, теперь можно
использовать на разных стадиях нашего конвейера непрерывной
поставки с необходимыми нам изменениями.

#### Создать prod и stage конфигурации

* Создать prod конфигурацию

Содержимое директории prod
```editorconfig
prod
├── main.tf
├── outputs.tf
├── terraform.tfvars
└── variables.tf
```

* Отредактировать main.tf для использования модулей
```terraform
provider "yandex" {
  service_account_key_file = var.account_key_path
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  version                  = 0.35
}

module "app" {
  source = "../modules/app"
  public_key_path = var.public_key_path
  app_disc_image = var.app_disc_image
  subnet_id = var.subnet_id
}

module "db" {
  source = "../modules/db"
  public_key_path = var.public_key_path
  db_disc_image = var.db_disc_image
  subnet_id = var.subnet_id
}
```

#### Доп. задание: настроить хранение стейт на удалённом бекенде.

Состояние Terraform описывает текущую развернутую инфраструктуру и хранится в файлах с расширением .tfstate.
Файл состояния создается после развертывания инфраструктуры и может быть сразу загружен в Object Storage.
Загруженный файл состояния будет обновляться после изменений созданной инфраструктуры.

* Создать [статические ключи доступа](https://cloud.yandex.ru/docs/iam/concepts/authorization/access-key) совместимые с AWS API

По [инструкции](https://cloud.yandex.ru/docs/iam/operations/sa/create-access-key)
создать статические ключи доступа. В результате key_id нужно поместить в access_key, а secret в secret_key.
```editorconfig
access_key:
  id: some-id
  service_account_id: some-account-id
  created_at: "2021-07-19T20:33:42.790725131Z"
  key_id: acces-key-id
secret: secret-key-id
```

* Создать backet для хранения .tfstate

Создать ресурс `yandex_storage_bucket` и применить изменения `terraform apply`
```terraform
resource "yandex_storage_bucket" "terraform" {
  access_key = "access-key"
  secret_key = "secret-key"
  bucket = "terraform-hw"
}
```

Либо создать его используя web-интерфейс yandex cloud.

* Создать файл backend.tf с описанием бэкенда для хранения .tfstate

```terraform
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-hw"
    region     = "ru-central1"
    key        = "prod/terraform.tfstate"
    access_key = "access-key"
    secret_key = "secret-key"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```

</details>

## HW-08 (Lecture 10)
#### branch: `ansible-1`
- [X] Установить ansible
- [X] Ознакомиться с базовыми функциями и инвентори
- [X] Написать простой плейбук
- [ ] Доп. задание: настроить динамический инвентори

<details><summary>Решение</summary>

#### Установить ansible

* Проверить, что установлен python, рекомендуемая версия 2.7
```editorconfig
python --version
```

* [Установить ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) используя pip или easy_install
```editorconfig
$ ansible --version
ansible [core 2.11.3]
  config file = None
  ...
  python version = 3.9.6 (default, Jun 29 2021, 06:20:32) [Clang 12.0.0 (clang-1200.0.32.29)]
  jinja version = 3.0.1
  libyaml = True
```

#### Ознакомиться с базовыми функциями и инвентори

Ansible управляет инстансами виртуальных машин (c Linux ОС) используя
SSH-соединение. Поэтому для управление инстансом при помощи Ansible
нам нужно убедиться, что есть возможность подключиться к нему по SSH.
Для управления хостами при помощи Ansible на них также должен быть
установлен Python >=2.7

* Поднять инфраструктуру, описанную в terraform/stage директории

* Создать inventory файл, с описанием инфраструктуры
```ini
appserver ansible_host=app_host_ip ansible_user=ubuntu \
 ansible_private_key_file=~/.ssh/otus_devops
```

Убедимся, что ansible может управлять хостом
```editorconfig
ansible appserver -i ./inventory -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Модуль `ping` позволяет протестировать соединение с хостом, как видно из результата применения команды на хсте ничего не было изменено.

* Повторить те же действия для инстанса db

* Создать конфигурационный файл для ansible

```editorconfig
[defaults]
inventory = ./inventory
remote_user = ubuntu
private_key_file = ~/.ssh/otus_devops
host_key_checking = False
retry_files_enabled = False
```

Теперь можно упростить инвентори файл:
```ini
appserver ansible_host=app_ip
dbserver ansible_host=db_ip
```

После создания конфигурационного файла формат ansible команд будет следующий:
```editorconfig
$ ansible dbserver -m command -a uptime
dbserver | CHANGED | rc=0 >>
 12:14:47 up  3:13,  1 user,  load average: 0.04, 0.02, 0.00
```

* Определить группы хостов

Управлять при помощи Ansible отдельными хостами становится
неудобно, когда этих хостов становится более одного.
В инвентори файле можно определить группу хостов для управления
конфигурацией сразу нескольких хостов.
Список хостов указывается под названием группы, каждый новый хост
указывается в новой строке.

```ini
[app] # ⬅ Это название группы
appserver ansible_host=host_ip # ⬅ Cписок хостов в данной группе

[db]
dbserver ansible_host=db_ip
```

Проверка:
```editorconfig
$ ansible app -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

* Использовать yaml инвентори
```yaml
app:
  hosts:
    appserver:
      ansible_host: app_ip
db:
  hosts:
    dbserver:
      ansible_host: db_ip
```

Проверка:
```editorconfig
$ ansible all -i ./inventory.yml -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

* Выполнить команды для проверки наличия библиотек на хостах

Проверка `ruby`
```editorconfig
$ ansible app -m command -a 'ruby -v'
appserver | CHANGED | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
```

Проверка `mongod`
```editorconfig
$ ansible db -m command -a 'systemctl status mongod'
dbserver | CHANGED | rc=0 >>
* mongod.service - MongoDB Database Server
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2021-07-27 09:01:25 UTC; 3h 23min ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 651 (mongod)
   CGroup: /system.slice/mongod.service
           `-651 /usr/bin/mongod --config /etc/mongod.conf

Jul 27 09:01:25 fhmlunq2u4pj4f378onl systemd[1]: Started MongoDB Database Server.
```

* Склонировать репозиторий используя anible
```editorconfig
$ ansible app -m git -a \
 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit'
appserver | CHANGED => {
    "after": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "before": null,
    "changed": true
}
```

Повторный запуск покажет, что репозиторий уже склонирован и никаких изменений не произошло
```editorconfig
$ ansible app -m git -a \
 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit'
appserver | SUCCESS => {
    "after": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "before": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "changed": false,
    "remote_url_changed": false
}
```

#### Написать простой плейбук

* Создать плейбук
```yaml
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
```

* Запустить плейбук

Перед выполнением необходимо удалить склонированный репозиторий
`ansible app -m command -a 'rm -rf ~/reddit'`

```editorconfig
ansible-playbook clone.yml

PLAY [Clone] ***********************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************************************************************
ok: [appserver]

TASK [Clone repo] ******************************************************************************************************************************************************************************************************
changed: [appserver]

PLAY RECAP *************************************************************************************************************************************************************************************************************
appserver                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

</details>

## HW-09 (Lecture 11)
#### branch: `ansible-2`
- [X] Один плейбук, один сценарий
- [X] Настроить инстанс приложения
- [X] Один плейбук, несколько сценариев
- [X] Несколько плейбуков
- [X] Изменить провижининг в Packer

<details><summary>Решение</summary>

#### Один плейбук, один сценарий

* Создать плейбук

Плейбук может состоять из одного или нескольких сценариев (plays). Сценарий позволяет группировать набор заданий (tasks), который
Ansible должен выполнить на конкретном хосте (или группе).

Сценарий для mongodb:
```yaml
---
- name: Configure hosts & deploy application # <-- Словесное описание сценария (name)
  hosts: all # <-- Для каких хостов будут выполняться описанные ниже таски (hosts)
  tasks: # <-- Блок тасков (заданий), которые будут выполняться для данных хостов
```

Скопировать параметризированный локальный конфиг файл MongoDB на удаленный
хост по указанному
```yaml
---
- name: Configure hosts & deploy application # <-- Словесное описание сценария (name)
  hosts: all # <-- Для каких хостов будут выполняться описанные ниже таски (hosts)
  tasks: # <-- Блок тасков (заданий), которые будут выполняться для данных хостов
    - name: Change mongo config file
      become: true # <-- Выполнить задание от root
      template:
        src: templates/mongod.conf.j2 # <-- Путь до локального файла-шаблона
        dest: /etc/mongod.conf # <-- Путь на удаленном хосте
        mode: 0644 # <-- Права на файл, которые нужно установить
```

Для возможности запуска отдельных тасок, а не всего сценария, определить для каждой таски тег
```yaml
---
- name: Configure hosts & deploy application # <-- Словесное описание сценария (name)
  hosts: all # <-- Для каких хостов будут выполняться описанные ниже таски (hosts)
  tasks: # <-- Блок тасков (заданий), которые будут выполняться для данных хостов
    - name: Change mongo config file
      become: true # <-- Выполнить задание от root
      template:
        src: templates/mongod.conf.j2 # <-- Путь до локального файла-шаблона
        dest: /etc/mongod.conf # <-- Путь на удаленном хосте
        mode: 0644 # <-- Права на файл, которые нужно установить
      tags: db-tag # <-- Список тэгов для задачи
```

Создать параметризованный конфиг для mongodb
```gotemplate
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: {{ mongo_port | default('27017') }}
  bindIp: {{ mongo_bind_ip }}
```

Пробный (dry-run) прогон плейбука
```editorconfig
$ ansible-playbook reddit_app.yml --check --limit db
```

В результате получим ошибку `{"changed": false, "msg": "AnsibleUndefinedVariable: 'mongo_bind_ip' is undefined"}`
Не определена переменная, которая используется в шаблоне.

Для исправления ошибки необходимо добавить блок vars в плейбук:
```yaml
vars:
  mongo_bind_ip: 0.0.0.0 # <-- Переменная задается в блоке vars
```

После пробного запуска получен следующий результат:
```editorconfig
ok=2    changed=1
```

* Добавить handlers

Handlers запускаются только по оповещению от других задач.
Таск шлет оповещение handler-у в случае, когда он меняет свое
состояние. По этой причине handlers удобно использовать для перезапуска сервисов.

В плейбуке описать секцию с handler:
```yaml
handlers: # <-- Добавим блок handlers и задачу
- name: restart mongod
  become: true
  service: name=mongod state=restarted
```

После запуска плейбука будет виден запуск handler:
```editorconfig
RUNNING HANDLER [restart mongod]
```

#### Настроить инстанс приложения

* Создать unit файл для приложения:
```editorconfig
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
EnvironmentFile=/home/appuser/db_config
User=appuser
WorkingDirectory=/home/appuser/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```

* Создать таск и handler для копирования unit файла и запуска puma:
```yaml
tasks:
  - name: Add unit file for Puma
    become: true
    copy:
      src: files/puma.service
      dest: /etc/systemd/system/puma.service
    tags: app-tag
    notify: reload puma
handlers: # <-- Добавим блок handlers и задачу
  - name: enable puma
    become: true
    systemd: name=puma enabled=yes
    tags: app-tag
```

Что бы приложение знало по какому адресу обращаться к бд, вынести адрес в переменные окружения:
`EnvironmentFile=/home/appuser/db_config`

* Создать шаблон для приложения:
```editorconfig
DATABASE_URL={{ db_host }}
```

* Создать таск для копирования файла шаблона:
```yaml
- name: Add config for DB connection
  template:
    src: templates/db_config.j2
    dest: /home/appuser/db_config
  tags: app-tag
```

* Добавить переменную в плейбук:
```yaml
db_host: 10.128.0.23
```

После запуска плейбука результат будет следующий: `ok=4    changed=3`

* Деплой приложения

* Добавить таски на деплой кода и установку зависимостей
```yaml
- name: Fetch the latest version of application code
  git:
    repo: 'https://github.com/express42/reddit.git'
    dest: /home/ubuntu/reddit
    version: monolith # <-- Указываем нужную ветку
  tags: deploy-tag
  notify: reload puma
- name: Bundle install
  bundler:
    state: present
    chdir: /home/ubuntu/reddit # <-- В какой директории выполнить команду bundle
  tags: deploy-tag
```

* Выполнить деплой `ansible-playbook reddit_app.yml --limit app --tags deploy-tag`
```editorconfig
ok=3    changed=3
```

#### Один плейбук, несколько сценариев

В предыдущей части был создан один плейбук, в котором определён один сценарий (play) и для запуска нужных тасков на заданной
группе хостов необходима была опция --limit для указания группы хостов и --tags для указания нужных тасков.
Проблема такого подхода состоит в том, что необходимо помнить при каждом запуске плейбука, на каком хосте какие таски
необходимо применить, и передавать это в опциях командной строки.

* Сценарий для mongodb
```yaml
---
- name: Configure mongodb
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
    - name: restart mongod
      service: name=mongod state=restarted
```

* Сценарий для app
```yaml
- name: Configure application hosts
  hosts: app
  tags: app-tag
  become: true
  vars:
    db_host: 10.132.0.2
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
    - name: reload puma
      systemd: name=puma state=restarted
```

* Сценарий для деплоя приложения
```yaml
- name: Deploy application
  hosts: app
  tags: deploy-tag
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith # <-- Указываем нужную ветку
      notify: restart puma
    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit # <-- В какой директории выполнить команду bundle

  handlers:
    - name: restart puma
      become: true
      sysctl: name=puma state=restarted
```

#### Несколько плейбуков

Один плейбук - несколько сценариев решает проблему конфигурирования через теги, но с ростом числа управляемых сервисов, будет расти количество
различных сценариев и, как результат, увеличится объем плейбука.

* Несколько плейбуков

* Содержимое плейбука db
```yaml
---
- name: Configure mongodb
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
    - name: restart mongod
      service: name=mongod state=restarted
```

* Содержимое плейбука app
```yaml
---
- name: Configure application hosts
  hosts: app
  become: true
  vars:
    db_host: 10.128.0.15
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
    - name: reload puma
      systemd: name=puma state=restarted
```

* Содержимое плейбука deploy
```yaml
---
- name: Deploy application
  hosts: app
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith # <-- Указываем нужную ветку
      notify: restart puma
    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit # <-- В какой директории выполнить команду bundle

  handlers:
    - name: restart puma
      become: true
      sysctl: name=puma state=restarted
```

* Содержимое site.yml, в котором содержится конфигурация всей инфраструктуры
```yaml
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```

#### Изменить провижининг в Packer

* Создать плейбуки для установки ПО, необходимого в образах

* Содержимое файла `packer_app.yml`
```yaml
---
- name: Install ruby
  hosts: all
  become: true
  tasks:
  - name: Install ruby and other packages
    apt:
      name: "{{ item }}"
      state: present
      update_cache: true
    loop:
    - ruby-full
    - ruby-bundler
    - build-essential
    - git
```

* Содержимое файла `packer_db.yml`
```yaml
---
- name: Install and run mongodb
  hosts: all
  become: true
  tasks:
    # Добавим ключ репозитория для последующей работы с ним
    - name: Add APT key
      apt_key:
        url: https://www.mongodb.org/static/pgp/server-4.2.asc
        state: present

    - name: Add repository
      apt_repository:
        repo: 'deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse'
        state: present

    - name: Install packages
      apt:
        name: mongodb-org
        state: present
        update_cache: true

    - name: Configure service supervisor
      systemd:
        name: mongod
        enabled: yes
```

* Интегрировать ansible и packer заменив провиженеры
```json
{
  "type": "ansible",
  "playbook_file": "ansible/packer_app.yml"
}
...
{
  "type": "ansible",
  "playbook_file": "ansible/packer_db.yml"
}
```

</details>

## HW-10 (Lecture 12)
#### branch: `ansible-3`
- [X] Перенести плейбуки в раздельные роли
- [X] Описать два окружения
- [X] Использовать коммьюнити роль nginx
- [X] Использовать Ansible Vault для окружений

<details><summary>Решение</summary>

#### Перенести плейбуки в раздельные роли

В текущей реализации есть несколько существенных проблем, одна из которы состоит в том, что текущую
конфигурацию сложно версионировать и тяжело подстраивать для различных окружений.
Так же плейбуки не подходят как формат для распространения и переиспользования кода (нет версии, зависимостей и метаданных,
зато много хардкода)

Решить эти проблемы может использование ролей
Роли представляют собой основной механизм группировки и переиспользования конфигурационного кода в Ansible.
Роли позволяют сгруппировать в единое целое описание конфигурации отдельных сервисов и компонент системы (таски,
хендлеры, файлы, шаблоны, переменные).
Роли можно затем переиспользовать при настройке окружений, тем самым избежав дублирования кода.
Ролями можно также делиться и брать у сообщества (community) в [Ansible Galaxy](https://galaxy.ansible.com/)
Справка по использованию ansible galaxy: `ansible-galaxy -h`

* Ansible-galaxy помогает сформировать правильную структуру для роли
```editorconfig
ansible-galaxy init <role_name>
```

После выполнения команды `ansible-galaxy init app` будет создана роль app со следующей структурой:
```editorconfig
app
├── README.md
├── defaults        # <-- Директория для переменных по умолчанию
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta            # <-- Информация о роли, создателе и зависимостях
│   └── main.yml
├── tasks           # <-- Директория для тасков
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars            # <-- Директория для переменных, которые не должны
    └── main.yml    # переопределяться пользователем
```

* Создать роль для базы данных db

Описание таски:
```yaml
---
# tasks file for db
- name: Change mongo config file
  template:
    src: mongod.conf.j2
    dest: /etc/mongod.conf
    mode: 0644
  notify: restart mongod
```

Шаблон конфигурации mongodb
```editorconfig
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: {{ mongo_port | default('27017') }}
  bindIp: {{ mongo_bind_ip }}
```

Особенностью ролей также является, что модули template и copy, которые используются в тасках роли, будут по умолчанию
проверять наличие шаблонов и файлов в директориях роли templates и files соответственно.

Определение хендлера:
```yaml
---
# handlers file for db
- name: restart mongod
  service: name=mongod state=restarted
```

Определение переменных со значениями по умолчанию:
```yaml
---
# defaults file for db
mongo_port: 27017
mongo_bind_ip: 127.0.0.1
```

* Создать роль для приложения app

Описание таски:
```yaml
---
# tasks file for app
- name: Add unit file for Puma
  copy:
    src: puma.service
    dest: /etc/systemd/system/puma.service
  notify: reload puma

- name: Add config for DB connection
  template:
    src: db_config.j2
    dest: /home/ubuntu/db_config
    owner: ubuntu
    group: ubuntu

- name: enable puma
  systemd: name=puma enabled=yes
```

Шаблон конфигурации сервиса
```editorconfig
DATABASE_URL={{ db_host }}
```

Файл с init скриптом для запуска сервиса
```editorconfig
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
EnvironmentFile=/home/ubuntu/db_config
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'

[Install]
WantedBy=multi-user.target
```

Определение хендлера:
```yaml
---
# handlers file for app
- name: reload puma
  systemd: name=puma state=restarted
```

Определение переменных со значениями по умолчанию:
```yaml
---
# defaults file for app
db_host: 127.0.01
```

* Вызов ролей

Вызов роли в плейбуке для настройки базы данных
```yaml
---
- name: Configure mongodb
  hosts: db
  become: true

  vars:
    mongo_bind_ip: 0.0.0.0

  roles:
    - db
```

Вызов роли в плейбуке для настройки приложения
```yaml
---
- name: Configure application hosts
  hosts: app
  become: true

  vars:
    db_host: 10.128.0.14

  roles:
    - app
```

* Пересоздать инфраструктуру и применить плейбук
```editorconfig
$ ansible-playbook site.yml
```

#### Описать два окружения

* Создать под каждое окружение директорию и создать внутри инвентори файл для окружения

Теперь для выполнения плейбука необходимо явно передавать инвентори файл
```editorconfig
$ ansible-playbook -i environments/prod/inventory deploy.yml
```

Для определения окружения по-умолчанию необходимо добавить его в конфиг ansible
```editorconfig
[defaults]
inventory = ./environments/stage/inventory # Inventory по-умолчанию задается здесь
remote_user = ubuntu
private_key_file = ~/.ssh/otus_devops
host_key_checking = False
retry_files_enabled = False
```

* Задать переменные групп хостов

Параметризация конфигурации ролей за счет переменных дает возможность изменять настройки конфигурации, задавая
нужные значения переменных.
Ansible позволяет задавать переменные для групп хостов, определенных в инвентори файле.
Директория group_vars, созданная в директории плейбука или инвентори файла, позволяет создавать файлы (имена, которых
должны соответствовать названиям групп в инвентори файле) для определения переменных для группы хостов.

* Конфигурация stage

Определить файл group_vars/app, с переменными для группы хостов `app` из инвентори файла
```editorconfig
db_host: 10.128.0.19
```

Определить файл group_vars/db, с переменными для группы хостов `db` из инвентори файла
```editorconfig
mongo_bind_ip: 0.0.0.0
```

Определить файл group_vars/all, с пременными, которые будут доступны всем хостам окружения
```editorconfig
env: stage
```

* Конфигурация prod

Конфигурация аналогична stage

* Вывода информации об окружении

Определить переменную `env` в используемых ролях
```editorconfig
env: local
```

Для вывода информации об окружении необходимо добавить таск, используя модуль debug
```yaml
- name: Show info about the env this host belongs to
  debug:
    msg: "This host is in {{ env }} environment!!!"
```

* Организовать плейбукисогласно best practices

* Улучшить файл ansible.cfg

Содержимое файла `ansible.cfg`
```editorconfig
[defaults]
inventory = ./environments/stage/inventory # Inventory по-умолчанию задается здесь
remote_user = ubuntu
private_key_file = ~/.ssh/otus_devops
# Отключим проверку SSH Host-keys (поскольку они всегда разные для новых инстансов)
host_key_checking = False
# Отключим создание *.retry-файлов (они нечасто нужны, но мешаются под руками)
retry_files_enabled = False
# Явно укажем расположение ролей (можно задать несколько путей через ; )
roles_path = ./roles

[diff]
# Включим обязательный вывод diff при наличии изменений и вывод 5 строк контекста
always = True
context = 5
```

#### Использовать коммьюнити роль nginx

* Настроить обратное проксирование для приложения через nginx, используя роль [jdauphant.nginx](https://github.com/jdauphant/ansible-role-nginx)

Хорошей практикой является разделение зависимостей по окружениям.
Создать файл зависимостей `requirements.yml` для каждого окружения
```yaml
- src: jdauphant.nginx
  version: v2.21.1
```

Установить роль
```editorconfig
ansible-galaxy install -r environments/stage/requirements.yml
```

Для настройки nginx роли необходимо добавить переменные по умолчанию в группе app:
```editorconfig
---
db_host: 10.128.0.21
nginx_sites:
  default:
    - listen 80
    - server_name "reddit"
    - location / {
        proxy_pass http://127.0.0.1:9292;
      }
```

#### Использовать Ansible Vault для окружений

Для безопасной работы с приватными данными (пароли, приватные ключи и т.д.) используется механизм [Ansible Vault](https://docs.ansible.com/ansible/devel/user_guide/vault.html)
Данные сохраняются в зашифрованных файлах, которые при выполнении плейбука автоматически расшифровываются.
Таким образом, приватные данные можно хранить в системе контроля версий.

* Создать файл `vault.key` с паролем для шифрования

* Добавить опцию в `ansible.cfg`
```editorconfig
[defaults]
...
vault_password_file = vault.key
```

* Добавить плейбук для создания пользователей
```yaml
---
- name: Create users
  hosts: all
  become: true

  vars_files:
    - "{{ inventory_dir }}/credentials.yml"

  tasks:
    - name: create users
      user:
        name: "{{ item.key }}"
        password: "{{ item.value.password|password_hash('sha512', 65534|random(seed=inventory_hostname)|string) }}"
        groups: "{{ item.value.groups | default(omit) }}"
      with_dict: "{{ credentials.users }}"
```

* Создать файл со списком пользователей для каждого окружения `credentials.yml`
```yaml
ansible/environments/prod/credentials.yml

---
credentials:
  users:
    admin:
      password: admin123
      groups: sudo
```
```yaml
ansible/environments/stage/credentials.yml

---
credentials:
  users:
    admin:
      password: qwerty123
      groups: sudo
    qauser:
      password: test123
```

* Зашифровать файлы пользователей
```editorconfig
$ ansible-vault encrypt environments/prod/credentials.yml
```

Для расшифровки файла используется команда `decrypt`
```editorconfig
$ ansible-vault decrypt environments/prod/credentials.yml
```

Для изменения пременных используется команда `edit`

</details>
