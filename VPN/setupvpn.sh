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
