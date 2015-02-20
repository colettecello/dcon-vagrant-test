set -x

apt-get -y update

export DEBIAN_FRONTEND=noninteractive

# all the apt-gets
apt-get -y install \
        nginx mysql-server python-mysqldb git varnish

git clone https://github.com/MostAwesomeDude/dcon /var/dcon

apt-get -y install python-pip python-dev pwgen

# os stuff done

cd /var/dcon

pip install -r requirements.txt # install python deps

pwgen 50 1 > ./secret.key # dcon requires a secret value here

# dcon stores passwords unencrypted but this is how it does it:
touch passwords.dcon
echo "admin:password" >> passwords.dcon

# setup mysql for dcon user <--Where do I put the 
# username:password for mysql? dcon.yaml?
mysql -u root <<EOF
CREATE USER 'dcon'@'localhost' IDENTIFIED BY 'badpassword';
CREATE DATABASE dcon;
GRANT ALL PRIVILEGES ON *.* TO 'dcon'@'localhost';
FLUSH PRIVILEGES;
EOF

# use example config file for now:
# cp dcon.yaml.example dcon.yaml

# use dcon.yaml config from vagrant dir
cp /vagrant/dcon.yaml /var/dcon/dcon.yaml

python shell.py # create database (mysql for now)

chown -Rv nobody:nogroup /var/dcon

pip install gunicorn # install gunicorn

# configure gunicorn as a service
cp /vagrant/dcon.conf.init /etc/init/dcon.conf
initctl reload-configuration
service dcon start

# configure nginx
cp /vagrant/dcon.nginx /etc/nginx/sites-available/
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/dcon.nginx /etc/nginx/sites-enabled/dcon.nginx

# configure varnish
cp /vagrant/varnish.dcon /etc/default/varnish

service nginx restart
service varnish restart
# ip -4 addr show
