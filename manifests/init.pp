# == Class: pgbouncer
#
# Installs the pbouncer package and configures the ini.
#
# === Examples
#
#  class { pgbouncer: }
#
# === Hiera example
#
# Hieradata gets merged overtop of defaults. All valid config options excepted
#
#  pgbouncer::params::config_params:
#    listen_port: 7432
#    max_client_conn: 100
#
# === Authors
#
# CJ Estel
#
# === Credits
#
# This module is loosely based on
# https://bitbucket.org/landcareresearch/puppet-pgbouncer
#
# === Copyright
#
# CoverMyMeds
#
# === License
#
# GPL-3.0+
#
# === Parameters
#
# userlist is an empty array by default. You can create an array in hieradata
# like the example below or you can call the resource directly from a third
# party module
# pgbouncer::userlist:
#   - user: <user>
#     password: <password>
#   - user: <user2>
#     password: <password2>
#
# databases is an empty array by default. You can create an array in hieradata
# like the example below or you can call the resource direclty from a third
# party module Set hieradata hash array for "pgbouncer::databases" to set values
# Example:
# pgbouncer::databases
#   - source_db: postgres
#     host: localhost
#     dest_db: postgres
#     auth_user: postgres
#
# paramtmpfile is the temporary file the module uses to stitch together pieces
# using puppet concat. Its located in the tmp directory by default.
#
# default_config_params is a hash of the necessary params needed to start
# pgbouncer. If you choose to override this, you must specify all of the default
# params and not just the one you want to override.
#
# config_params is a hash that gets merged with the default params. If you want
# to override a single value, this would be the variable to do it in. All of the
# available params found in the below link can be added to the config from this
# hash.
# Link to pgbouncer doc: http://pgbouncer.projects.pgfoundry.org/doc/config.html
# Example:
# pgbouncer::config_params:
#   port:8765
#   dns_max_ttl: 16
#
# pgbouncer_package_name is the name of the package that should be installed. By
# default, this should be picked by the OS, but you can specify a name here if
# you'd like to override the package name. You could possibly use this to
# specify an older version as well.
#
# conffile is the name of the configuration file
#
# userlist_file is the name of the auth_file where the userlist is stored
#
# deb_default_file is a file specific to ubuntu that loads a startup file
#
class pgbouncer (
  Array $userlist                     = $pgbouncer::params::userlist,
  Array $databases                    = $pgbouncer::params::databases,
  String $paramtmpfile                = $pgbouncer::params::paramtmpfile,
  Hash $default_config_params         = $pgbouncer::params::default_config_params,
  Hash $config_params                 = $pgbouncer::params::config_params,
  String $pgbouncer_package_name      = $pgbouncer::params::pgbouncer_package_name,
  String $conffile                    = $pgbouncer::params::conffile,
  String $userlist_file               = $pgbouncer::params::userlist_file,
  String $deb_default_file            = $pgbouncer::params::deb_default_file,
  Boolean $service_start_with_system  = $pgbouncer::params::service_start_with_system,
  String $user                        = $pgbouncer::params::user,
  String $group                       = $pgbouncer::params::group,
  Boolean $require_repo               = $pgbouncer::params::require_repo,
) inherits pgbouncer::params {
  # merge the defaults and custom params
  $load_config_params = merge($default_config_params, $config_params)

  anchor { 'pgbouncer::begin': }

  # Same package name for both redhat based and debian based
  case $facts['os']['family'] {
    'RedHat', 'Linux': {
      $package_require = $require_repo ? {
        true  => [Class['postgresql::repo::yum_postgresql_org'], Anchor['pgbouncer::begin']],
        false => Anchor['pgbouncer::begin'],
      }
      package { $pgbouncer_package_name:
        ensure  => installed,
        require => $package_require,
      }
    }
    'FreeBSD', 'Debian': {
      package { $pgbouncer_package_name:
        ensure  => installed,
      }
    }
    default: {
      fail("Module ${module_name} is not supported on ${facts['os']['name']}")
    }
  }
  # verify we have config file managed by concat
  concat { $conffile:
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0640',
  }

  # verify we have auth_file managed by concat
  concat { $userlist_file:
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0640',
  }

  # build the pgbouncer parameter piece of the config file
  concat::fragment { "${paramtmpfile}_params":
    target  => $conffile,
    content => template('pgbouncer/pgbouncer.ini.param.part.erb'),
    order   => '03',
    require => Package[$pgbouncer_package_name],
  }

  # check if debian
  if $facts['os']['family'] == 'Debian' {
    file { $deb_default_file:
      ensure  => file,
      source  => 'puppet:///modules/pgbouncer/pgbouncer',
      require => Package[$pgbouncer_package_name],
      before  => Concat[$userlist_file],
    }
  }
  # check if we have an authlist
  if $userlist {
    pgbouncer::userlist { 'pgbouncer_module_userlist':
      auth_list    => $userlist,
      paramtmpfile => $paramtmpfile,
    }
  }

  #build the databases base piece of the config file
  concat::fragment { "${paramtmpfile}_database":
    target  => $conffile,
    content => template('pgbouncer/pgbouncer.ini.databases.part1.erb'),
    order   => '01',
  }

  #build the users base piece of the config file
  concat::fragment { "${paramtmpfile}_users":
    target  => $conffile,
    content => template('pgbouncer/pgbouncer.ini.users.part1.erb'),
    order   => '05',
  }

  # check if we have a database list and create entries
  if $databases {
    pgbouncer::databases { 'pgbouncer_module_databases':
      databases => $databases,
    }
  }

  service { 'pgbouncer':
    ensure    => running,
    enable    => $service_start_with_system,
    subscribe => Concat[$userlist_file, $conffile],
  }

  anchor { 'pgbouncer::end':
    require => Service['pgbouncer'],
  }
}
