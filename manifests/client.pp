# a PostgreSQL server that's backed up to a remote pgbackrest "repository"
class pgbackrest::client(
  Stdlib::Fqdn $repository_fqdn,
  String[1] $collect_tag = "pgbackrest::repository::${repository_fqdn}",
  Stdlib::Fqdn $stanza_name = $facts['networking']['fqdn'],
  Integer $pg_cluster_version = 15,
  String[1] $pg_cluster_name = 'main',
  String[1] $pg_cluster_path = "/var/lib/postgresql/${pg_cluster_version}/${pg_cluster_name}",
) {
  include pgbackrest
  # TODO: generate SSH key here
  @@pgbackrest::repository::stanza { $stanza_name:
    tag => $collect_tag,
    # ssh_key_params => TODO
  }
  # XXX: duplicates some of pgbackrest::repository::stanza
  pgbackrest::config_file { 'server':
    config => {
      'global'     => {
        'log-level-file'  => 'detail',
        'repo1-path'      => '/var/lib/pgbackrest',
        'repo1-host'      => $repository_fqdn,
        'repo1-host-user' => 'postgres', # XXX: hardcoded
      },
      $stanza_name => {
        'pg1-path' => $pg_cluster_path,
      }
    }
  }
}
