# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include pgbackrest::yumrepos
class pgbackrest::yumrepos(
  # optional settings
  Enum['latest','installed','absent'] $release_rpm_ensure,
  Optional[Integer] $enable_version = undef,
  # change these only if the upstream package repo is restructured
  String $release_rpm,
  String $release_rpm_source,
  Array[Integer] $pgsql_versions,
) {
  package { $release_rpm:
    ensure   => $release_rpm_ensure,
    source   => $release_rpm_source,
    provider => 'rpm',
  }
  $pgsql_versions.each |$version| {
    $enabled = $version ? {
      $enable_version => 1,
      default         => 0,
    }
    yumrepo { "pgdg${version}":
      enabled => $enabled,
    }
  }
}
