# a PostgreSQL server that's backed up to a remote pgbackrest "repository"
#
# the stanza_name is also used as a hostname by the repository to connect back to the client
class pgbackrest::client(
  Stdlib::Fqdn $repository_fqdn,
  String[1] $server_collect_tag = "pgbackrest::server::${repository_fqdn}",
  String[1] $repository_collect_tag = "pgbackrest::repository::${repository_fqdn}",
  Stdlib::Fqdn $stanza_name = $facts['networking']['fqdn'],
  String[1] $unix_user = "pgbackrest-${$facts['networking']['hostname']}",
  String[1] $pg_user = 'postgres',
  Integer $pg_cluster_version = 15,
  String[1] $pg_cluster_name = 'main',
  String[1] $pg_cluster_path = "/var/lib/postgresql/${pg_cluster_version}/${pg_cluster_name}",
  Boolean $manage_ssh = true,
) {
  include pgbackrest

  if $manage_ssh {
    if $facts['ssh_keys_users'] and $facts['ssh_keys_users'][$pg_user] and $facts['ssh_keys_users'][$pg_user]['id_rsa.pub'] {
      @@pgbackrest::repository::stanza { $stanza_name:
        username       => $unix_user,
        tag            => $server_collect_tag,
        ssh_key_params => $facts['ssh_keys_users'][$pg_user]['id_rsa.pub'],
      }
    } else {
      # XXX: assumes pg_user exists
      ssh_keygen { $pg_user: }
    }
    # authorize the repository's SSH keys to connect to this server to
    # pull full backups
    Ssh_authorized_key <<| tag == "pgbackrest::client::${unix_user}::${repository_fqdn}" |>>
    ensure_resource('file', "/etc/ssh/puppetkeys/${pg_user}", { owner => 'root', mode  => '0444', })
  }

  # XXX: duplicates some of pgbackrest::repository::stanza
  pgbackrest::config_file { 'server':
    config => {
      'global'     => {
        'log-level-file'  => 'detail',
        'repo1-path'      => '/var/lib/pgbackrest',
        'repo1-host'      => $repository_fqdn,
        'repo1-host-user' => $unix_user,
      },
      $stanza_name => {
        'pg1-path' => $pg_cluster_path,
      }
    }
  }
}
