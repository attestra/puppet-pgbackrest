# a PostgreSQL server that's backed up to a remote pgbackrest "repository"
class pgbackrest::client(
  Stdlib::Fqdn $repository_fqdn,
  String[1] $server_collect_tag = "pgbackrest::server::${repository_fqdn}",
  String[1] $repository_collect_tag = "pgbackrest::repository::${repository_fqdn}",
  Stdlib::Fqdn $stanza_name = $facts['networking']['fqdn'],
  String[1] $pg_user = 'postgres',
  Integer $pg_cluster_version = 15,
  String[1] $pg_cluster_name = 'main',
  String[1] $pg_cluster_path = "/var/lib/postgresql/${pg_cluster_version}/${pg_cluster_name}",
  Boolean $manage_ssh = true,
) {
  include pgbackrest

  if $manage_ssh {
    ssh::keygen { $pg_user: }
    if $facts['ssh_keys_users'] and $facts['ssh_keys_users'][$pg_user] and $facts['ssh_keys_users'][$pg_user]['id_rsa.pub'] {
      @@pgbackrest::repository::stanza { $stanza_name:
        tag            => $server_collect_tag,
        ssh_key_params => $facts['ssh_keys_users'][$pg_user]['id_rsa.pub'],
      }
    }
    # authorize the repository's SSH keys to connect to this server to
    # pull full backups
    Ssh_authorized_key <<| tag == $repository_collect_tag |>>
  }

  # XXX: duplicates some of pgbackrest::repository::stanza
  pgbackrest::config_file { 'server':
    config => {
      'global'     => {
        'log-level-file'  => 'detail',
        'repo1-path'      => '/var/lib/pgbackrest',
        'repo1-host'      => $repository_fqdn,
        'repo1-host-user' => $pg_user,
      },
      $stanza_name => {
        'pg1-path' => $pg_cluster_path,
      }
    }
  }
}
