# farir1408_infra
farir1408 Infra repository

## HW-03 (Lecture 5)
### branch: `cloud-bastion`
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
