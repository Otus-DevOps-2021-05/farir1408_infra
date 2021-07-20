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
