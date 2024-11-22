# @summary Configures pgBackRest
#
# Configures pgBackRest
#
# @example
#   include pgbackrest::config
#
class pgbackrest::config(
  String $filename   = '/etc/pgbackrest.conf',
  String $directory  = '/etc/pgbackrest/conf.d',
  Boolean $show_diff = true,
) {
  # XXX: hardcoded, switch to extlib::mkdir_p after Puppet 7 upgrade
  file { '/etc/pgbackrest':
    ensure => directory,
  }
  file { $directory:
    ensure => directory,
  }
  pgbackrest::config_file { $filename:
    filename  => $filename,
    show_diff => $show_diff,
    config    => $pgbackrest::config,
  }
}
