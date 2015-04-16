

include '::mysql::server'

# all the apt-gets

package { 'python-mysqldb' :
    ensure => installed,
}

package { 'git' :
    ensure => installed,
}

package { 'nginx' :
    ensure => installed,
}

package { 'pwgen' :
    ensure => installed,
}

# creates the dcon repo

vcsrepo { '/var/dcon' :
  ensure    => present,
  provider  => git,
  source    => 'git://github.com/MostAwesomeDude/dcon.git',
}

class { 'python' :
  version   => 'system',
  pip       => true,
  dev       => true,
  gunicorn  => true,
  require   => Vcsrepo ['/var/dcon'],
}

exec { 'requirements' :
  command => '/usr/bin/pip install -r /var/dcon/requirements.txt',
  creates => '/usr/local/lib/python2.7/dist-packages/parsley.py',
  require => Class ['python'],
}

# sets up secret hash for dcon to use

exec { 'make secret.key':
  command  => '/usr/bin/pwgen 50 1 > /var/dcon/secret.key',
  creates => '/var/dcon/secret.key',
  require => Vcsrepo['/var/dcon'], 
}

# dcon doesn't encrypt passwords, but here it is

file {'/var/dcon/passwords.dcon':
   ensure => present,
   require => Vcsrepo['/var/dcon'],
   contents => "admin:password",
}


# setup dcon database before activating app

mysql::db { 'dcon' :
  user     => 'dcon',
  password => 'badpassword',
  host     => 'localhost',
  grant    => ['ALL'], 
  require  => [ Exec ['make passwords.dcon'], Exec ['make secret.key'] ],
}

# use vagrant dcon.yaml config

file { 'dcon.yaml' :
    path    => '/var/dcon/dcon.yaml',
    ensure  => present,
    require => Vcsrepo ['/var/dcon'],
    source  => '/vagrant/dcon.yaml',
}

# make the database, start the app
exec { 'shell.py' :
  path    => '/usr/bin',
  command => 'python /var/dcon/shell.py || touch extra.txt',  
  creates => '/var/dcon/extra.txt',
  require =>[ Exec ['make passwords.dcon'], 
              Exec ['make secret.key'], 
              File ['dcon.yaml'] ],
}

# make the permissions right
exec { 'chown dcon' :
  path    => '/bin',
  command => 'chown -Rv nobody:nogroup /var/dcon || touch /var/dcon/extra1.txt',
  creates => '/var/dcon/extra1.txt',
  require => Exec ['shell.py'],
} 

directory{'/var/dcon':
	owner => 'nobody',
	group => 'nogroup',
	require => Vcsrepo ['/var/dcon'],
}
		
# sets up gunicorn settings
file { 'gunicorn conf' :
  path    => '/etc/init/dcon.conf',
  ensure  => present,
  require => [Class ['python'], Exec ['chown dcon']],
  source  => "/vagrant/dcon.conf.init",
}

# make gunicorn a service & start it
exec { 'initctl reload' :
  path    => '/sbin',
  command => 'initctl reload-configuration',
  require => File ['gunicorn conf'],
}

# FIXME start dcon with a puppet service object instead of an exec

exec { 'start dcon' :
  path    => '/usr/sbin',
  command => 'service dcon start',
  creates => '/var/dcon/gunicorn.log',
  require => Exec ['initctl reload'],
}

# sets up nginx with dcon settings
file { 'rm-nginx-default' :
   path => '/etc/nginx/sites-enabled/default',
   ensure => absent,
   require => Package['nginx'],
}

file { 'setup-nginx-codebase' :
   path => '/etc/nginx/sites-enabled/dcon.nginx',
   ensure => present,
   require => Package['nginx'],
   source => "/vagrant/dcon.nginx",
}

