# @summary Installs the pgBackRest package
#
# Installs the pgBackRest package
#
# @example
#   include pgbackrest::package
#
class pgbackrest::package() {
  package { 'pgbackrest':
    ensure => $pgbackrest::version,
  }
}
