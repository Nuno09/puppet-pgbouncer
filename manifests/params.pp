# == Class: pgbouncer::params
#
# Private class included by pgbouncer to set parameters
#
class pgbouncer::params (
  Array $userlist                    = [],
  Array $databases                   = [],
  String $paramtmpfile                = '/tmp/pgbouncer-paramtmpfile',
  Hash $config_params                = {},
  String $pgbouncer_package_name     = 'pgbouncer',
  String $deb_default_file           = '',
  Boolean $service_start_with_system = true,
  String $user                       = 'pgbouncer',
  String $group                      = 'pgbouncer',
  Boolean $require_repo              = true,
) {
  # === Set OS specific variables === #
  case $facts['os']['family'] {
    'RedHat', 'Linux': {
      $logfile                 = '/var/log/pgbouncer/pgbouncer.log'
      $pidfile                 = '/var/run/pgbouncer/pgbouncer.pid'
      $confdir                 = '/etc/pgbouncer'
      $conffile                = "${confdir}/pgbouncer.ini"
      $userlist_file           = "${confdir}/userlist.txt"
      $unix_socket_dir         = '/tmp'
    }
    'Debian': {
      $logfile                 = '/var/log/postgresql/pgbouncer.log'
      $pidfile                 = '/var/run/postgresql/pgbouncer.pid'
      $confdir                 = '/etc/pgbouncer'
      $conffile                = "${confdir}/pgbouncer.ini"
      $userlist_file           = "${confdir}/userlist.txt"
      $unix_socket_dir         = '/var/run/postgresql'
      $deb_default_file        = '/etc/default/pgbouncer'
    }
    'FreeBSD': {
      $logfile                 = '/var/log/pgbouncer/pgbouncer.log'
      $pidfile                 = '/var/run/pgbouncer/pgbouncer.pid'
      $confdir                 = '/usr/local/etc'
      $conffile                = "${confdir}/pgbouncer.ini"
      $userlist_file           = "${confdir}/pgbouncer.users"
      $unix_socket_dir         = '/tmp'
    }
    default: {
      fail("Module ${module_name} is not supported on ${facts['os']['name']}")
    }
  }
  # === Setup default parameters === #
  $default_config_params      = {
    logfile                     => $logfile,
    pidfile                     => $pidfile,
    unix_socket_dir             => $unix_socket_dir,
    auth_file                   => $userlist_file,
    listen_addr                 => '*',
    listen_port                 => '6432',
    admin_users                 => 'postgres',
    stats_users                 => 'postgres',
    auth_type                   => 'trust',
    pool_mode                   => 'session',
    server_reset_query          => 'DISCARD ALL',
    server_check_query          => 'select 1',
    server_check_delay          => '30',
    max_client_conn             => '1000',
    default_pool_size           => '20',
  }
}
