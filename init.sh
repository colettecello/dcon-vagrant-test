set -x

if [[ ! -e /.updated ]]; then
    apt-get -y update && apt-get -y upgrade && touch /.updated
fi

export DEBIAN_FRONTEND=noninteractive

test -d /etc/puppet/modules/stdlib || puppet module install puppetlabs-stdlib --version 3.2.0 
test -d /etc/puppet/modules/mysql || puppet module install puppetlabs-mysql --version 0.6.1 
# puppet module install example42-puppi --version 2.1.9
test -d /etc/puppet/modules/vcsrepo || puppet module install puppetlabs-vcsrepo 
test -d /etc/puppet/modules/python || puppet module install stankevich-python 
