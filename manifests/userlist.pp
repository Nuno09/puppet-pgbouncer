# == define: pgbouncer::userlist
#
# defined type that can be used to create the userlist in the auth_file
#
define pgbouncer::userlist (
  Array $auth_list     = [],
  String $paramtmpfile = '',
) {
  concat::fragment { $auth_list[0]['user']:
    target  => $pgbouncer::userlist_file,
    content => template('pgbouncer/userlist.txt.erb'),
    order   => '01',
  }

  concat::fragment { "${auth_list[0]['user']}_users":
    target  => $pgbouncer::conffile,
    content => template('pgbouncer/pgbouncer.ini.users.part2.erb'),
    order   => '06',
  }
}
