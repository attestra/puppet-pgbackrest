# a full server configuration on the pgbackrest repository
#
# this is a set or resources typically exported by the other
# PostgreSQL servers
#
# Lateral movement here is limited by the fact that we enforce the
# `$name` as the `pg1-host` and the resource name, so attempts at
# accessing other servers will be mitigated by duplicate resources,
# deliberately.
#
# TODO:
# isolation: server A shouldn't have access to server B's backups, watch out for lateral
# systemd timer per "stanza" (client) https://pgbackrest.org/user-guide.html#quickstart/schedule-backup
# expiration
define pgbackrest::repository::stanza(
  Integer $pg_cluster_version = 15,
  String[1] $pg_cluster_name = 'main',
  String[1] $pg_cluster_path = "/var/lib/postgresql/${pg_cluster_version}/${pg_cluster_name}",
  Hash $ssh_key_params = {},
) {
  pgbackrest::config_file { "${name}-${pg_cluster_name}-${pg_cluster_version}":
    config => {
      # XXX: "${name}-${pg_cluster_name}-${pg_cluster_version}" => {
      $name => {
        'pg1-host' => $name,
        'pg1-path' => $pg_cluster_path,
      }
    }
  }
  $username = "pgbackrest-${name}"
  user { $username:
    system => true,
  }
  if !empty($ssh_key_params) {
    ssh::keygen { $username: }

    # drop "line" key from params, which are not supported by ssh_authorized_keys
    $_ssh_key_params = $ssh_key_params.filter |$key, $value| { $key != 'line' }
    ssh_authorized_key { $username:
      target  => "/etc/ssh/puppetkeys/${username}",
      user    => 'root',
      options => [
        'restrict',
        'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }"',  #lint:ignore:single_quote_string_with_variables
      ],
      *       => $_ssh_key_params,
    }
    # TODO realize server's ssh key here, restricted to this $name
  }
}
