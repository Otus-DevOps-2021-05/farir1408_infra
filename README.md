# farir1408_infra
farir1408 Infra repository

## HW-03 (Lecture 5)
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
