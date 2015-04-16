
include '::mysql::server'

# all the apt-gets

$pkgs = [
    'python-mysqldb',
    'git',
    'nginx',
    'varnish',
]

package { $pkgs :
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
  before => Exec[setup-dcon],
}

# sets up secret hash for dcon to use

file {"/var/dcon/secret.key":
    content => "l34j5hlk34jbh6kwllkejrk2j3h44b5l23u4i234lj2k3hjhbn",
    require => Vcsrepo['/var/dcon'], 
}

# dcon doesn't encrypt passwords, but here it is

file {'/var/dcon/passwords.dcon':
   ensure => present,
   require => Vcsrepo['/var/dcon'],
   content => "admin:password\n",
}

# setup dcon database before activating app

mysql::db { 'dcon' :
    user     => 'dcon',
    password => 'badpassword',
    host     => 'localhost',
    grant    => ['ALL'], 
    require  => [
        File['/var/dcon/passwords.dcon'],
        File['/var/dcon/secret.key']
    ],
}

# use vagrant dcon.yaml config

file { 'dcon.yaml' :
    path    => '/var/dcon/dcon.yaml',
    ensure  => present,
    require => Vcsrepo ['/var/dcon'],
    source  => '/vagrant/dcon.yaml',
}

# make the database, start the app
exec { 'setup-dcon':
    cwd => '/var/dcon',
    command => '/usr/bin/python /var/dcon/shell.py && /usr/bin/touch /var/dcon/.configured',
    creates => '/var/dcon/.configured',
    require => File ['dcon.yaml'],
}

file {'/var/dcon':
	owner => 'nobody',
	group => 'nogroup',
    ensure => directory,
	require => Vcsrepo ['/var/dcon'],
}


if $operatingsystem == 'ubuntu' {
    # sets up gunicorn settings
    file { 'dcon-init-config' :
        path    => '/etc/init/dcon.conf',
        ensure  => present,
        require => [
            Class['python'],
            File['/var/dcon'],
            Exec[setup-dcon]
        ],
        source  => "/vagrant/dcon.conf.init",
    }

    # make gunicorn a service & start it
    exec { 'hup-init' :
        path    => '/sbin',
        command => 'initctl reload-configuration',
        require => File[dcon-init-config],
    }
}

# start dcon nginx varnish with a puppet service object

service {'dcon':
    ensure => running,
    enable => true,
    require => Exec [hup-init],
}

service {'nginx':
    ensure => running,
    enable => true,
    require => Package['nginx'],
}

service {'varnish':
    ensure => running,
    enable => true,
    require => Package['varnish'],
}

# sets up nginx with dcon settings
file { 'rm-nginx-default' :
    path => '/etc/nginx/sites-enabled/default',
    ensure => absent,
    require => [
        Package['nginx'],
        Exec['setup-dcon'],
    ]
}

file { 'setup-nginx-codebase' :
    path => '/etc/nginx/sites-enabled/dcon.nginx',
    ensure => present,
    require => [
        Package['nginx'],
        File[rm-nginx-default],
    ],
    source => '/vagrant/dcon.nginx',
    notify => Service[nginx]
}

# sets up varnish with dcon settings
file { 'setup-varnish' :
    path => '/etc/default/varnish/',
    ensure => present,
    require => [
        Package['varnish'],
        Exec['setup-dcon']
    ],
    source => '/vagrant/varnish.dcon',
    notify => Service[varnish],
}


