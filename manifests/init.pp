# @summary Installs and configures pgbackrest
#
# Installs and configures pgbackrest
#
# @example
#   include pgbackrest
#
class pgbackrest(
  Boolean $manage_package_repo,
  String $version,
  Hash[String,Hash] $config,
) {
  if $manage_package_repo {
    case $facts['os']['family'] {
      'Redhat': {
        contain pgbackrest::yumrepos
      }
      default: {
        fail "Repo management is not yet supported for ${facts['os']['family']}"
      }
    }
  }
  contain pgbackrest::package
  contain pgbackrest::config
}
