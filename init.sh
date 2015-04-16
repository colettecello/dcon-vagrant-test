set -x

apt-get -y update

export DEBIAN_FRONTEND=noninteractive

puppet module install puppetlabs-stdlib --version 3.2.0

puppet module install puppetlabs-mysql --version 0.6.1

# puppet module install example42-puppi --version 2.1.9

puppet module install puppetlabs-vcsrepo

puppet module install stankevich-python 

