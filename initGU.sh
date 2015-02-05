#!/bin/bash

set -x

apt-get -y update

export DEBIAN_FRONTEND=noninteractive

# get nginx key and add to apt program
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key

# all the apt-gets
apt-get -y install \
        nginx mysql-server git

git clone http://oculolinct.us:8080/dcon.git/ /var/dcon

apt-get -y install python-pip python-dev pwgen

# os stuff done

cd /var/dcon

pip install -r requirements.txt # install python deps

pwgen 50 1 > ./secret.key # dcon requires a secret value here

# dcon stores passwords unencrypted but this is how it does it:
touch passwords.dcon
echo "admin:password" >> passwords.dcon

# use example config file for now:
cp dcon.yaml.example dcon.yaml
#cp /vagrant/dcon.yaml /var/dcon/dcon.yaml

python shell.py # create database (sqlite for now)

pip install gunicorn

service start nginx # start nginx server (default conf for now)

