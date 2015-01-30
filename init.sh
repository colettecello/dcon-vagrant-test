#!/bin/bash

set -x

apt-get -y update

export DEBIAN_FRONTEND=noninteractive

apt-get -y install \
	apache2 mysql-server libapache2-mod-auth-mysql git

git clone http://oculolinct.us:8080/dcon.git/ /var/dcon

apt-get -y install python-pip python-dev pwgen

# os stuff done

cd /var/dcon

pip install -r requirements.txt # install python deps

pwgen 50 1 > ./secret.key  # dcon requires a secret value here

# dcon stores passwords unencrypted but this is how it does it:
touch passwords.dcon
echo "admin:password" >> passwords.dcon

# use example config file for now:
cp dcon.yaml.example dcon.yaml
#cp /vagrant/dcon.yaml /var/dcon/dcon.yaml

python shell.py # create database (sqlite for now)

pip install twisted # temporary testing app server

service apache2 stop # free up port 80

twistd -n web -p 80 --wsgi newrem.main.app &
