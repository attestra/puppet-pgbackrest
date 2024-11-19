# a full server configuration on the pgbackrest repository
#
# this is a set or resources typically exported by the other
# PostgreSQL servers
#
# TODO:
# SSH authorized_keys
# isolation: server A shouldn't have access to server B's backups, watch out for lateral
# systemd timer per "stanza" (client) https://pgbackrest.org/user-guide.html#quickstart/schedule-backup
# expiration
#
define pgbackrest::repository::stanza(
  String[1] $pg_cluster_host = $facts['networking']['fqdn'],
  Integer $pg_cluster_version = 15,
  String[1] $pg_cluster_name = 'main',
  String[1] $pg_cluster_path = "/var/lib/postgresql/${pg_cluster_version}/${pg_cluster_name}",
  Hash $ssh_key_params = {},
  ) {
    pgbackrest::config_file { $name:
      config => {
        $name => {
          'pg1-host' => $pg_cluster_host,
          'pg1-path' => $pg_cluster_path,
        }
      }
    }
    if !empty($ssh_key_params) {
      # TODO realize ssh key here
    }
  }
}
