set -x

apt-get -y update

export DEBIAN_FRONTEND=noninteractive

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
# cp /vagrant/dcon.yaml /var/dcon/dcon.yaml

python shell.py # create database (sqlite for now)

chown -Rv nobody:nogroup /var/dcon

pip install gunicorn # install gunicorn

cp /vagrant/dcon.conf.init /etc/init/dcon.conf
initctl reload-configuration
service dcon start

# configure nginx
cp /vagrant/dcon.nginx /etc/nginx/sites-available/
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/dcon.nginx /etc/nginx/sites-enabled/dcon.nginx

service nginx restart

ip -4 addr show
