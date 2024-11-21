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
# - global config not purged?
# - isolation: server A shouldn't have access to server B's backups, watch out for lateral
# - systemd timer per "stanza" (client) https://pgbackrest.org/user-guide.html#quickstart/schedule-backup
# - expiration
# - parameter docs
define pgbackrest::repository::stanza(
  Integer $pg_cluster_version = 15,
  String $username = "pgbackrest-${name}",
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
  user { $username:
    ensure     => present,
    system     => true,
    managehome => true,
  }
  # TODO: missing:
  # chmod +r /etc/ssh/puppetkeys/pgbackrest-weather-01 and .../postgres
  # mkdir /var/lib/pgbackrest/backup/weather-01.torproject.org /var/lib/pgbackrest/archive/weather-01.torproject.org/
  # chown $username ...
  # adduser $username postgres
  # sudo -u pgbackrest-weather-01 pgbackrest --lock-path=/tmp --stanza=weather-01.torproject.org stanza-create
  # per host lock file (--lock-path) and log files (--log-path)
  # archive_comand? -> docs?
  if $pgbackrest::repository::manage_ssh {
    ssh_keygen { $username:
      require => User[$username],
    }

    if !empty($ssh_key_params) {
      # drop "line" key from params, which are not supported by ssh_authorized_keys
      $_ssh_key_params = $ssh_key_params.filter |$key, $value| { $key != 'line' and $key != 'comment' }
      ssh_authorized_key { "${username}-${ssh_key_params['comment']}":
        target  => "/etc/ssh/puppetkeys/${username}",
        user    => 'root',
        options => [
          'restrict',
          'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }"',  #lint:ignore:single_quote_string_with_variables
        ],
        *       => $_ssh_key_params,
      }
      # TODO restricted to this $name
    }
  }
}
