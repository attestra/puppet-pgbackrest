# @summary Configures pgBackRest
#
# Configures pgBackRest
#
# @example
#   include pgbackrest::config
#
class pgbackrest::config(
  String $filename   = '/etc/pgbackrest.conf',
  Boolean $show_diff = true,
) {
  pgbackrest::config_file { $filename:
    filename  => $filename,
    show_diff => $show_diff,
    config    => $pgbackrest::config,
  }
}
