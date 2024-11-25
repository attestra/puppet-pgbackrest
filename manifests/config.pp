# @summary Configures pgBackRest
#
# Configures pgBackRest
#
# @example
#   include pgbackrest::config
#
class pgbackrest::config(
  String $filename          = '/etc/pgbackrest.conf',
  String $directory         = '/etc/pgbackrest/conf.d',
  Boolean $manage_directory = true,
  Boolean $show_diff        = true,
) {
  # ensure directory is purged if managed
  file { $directory:
    ensure  => 'directory',
    purge   => $manage_directory,
    recurse => $manage_directory,
  }
  pgbackrest::config_file { $filename:
    filename  => $filename,
    show_diff => $show_diff,
    config    => $pgbackrest::config,
  }
}
