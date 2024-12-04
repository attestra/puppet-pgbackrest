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
# Assuming the resource is trusted, a user sandbox is created for each
# stanza, which keeps server A from accessing server B's backups
# entirely.
#
# TODO:
# - global config not purged?
# - expiration
# - parameter docs
define pgbackrest::repository::stanza(
  Integer $pg_cluster_version = 15,
  String $username = "pgbackrest-${name}",
  String[1] $pg_cluster_name = 'main',
  String[1] $pg_cluster_path = "/var/lib/postgresql/${pg_cluster_version}/${pg_cluster_name}",
  Hash $ssh_key_params = {},
) {
  # create the config file for the stanza
  pgbackrest::config_file { "${name}-${pg_cluster_name}-${pg_cluster_version}":
    config => {
      # XXX: "${name}-${pg_cluster_name}-${pg_cluster_version}" => {
      $name => {
        'pg1-host'  => $name,
        'pg1-path'  => $pg_cluster_path,
        'lock-path' => "/var/lock/pgbackrest/${name}",
        'log-path'  => "/var/log/pgbackrest/${name}",
      }
    }
  }
  # create the actual "stanza"
  #
  # ...which are directories in /var/lib/pgbackrest, essentially
  #
  # this runs as root because the sandbox user doesn't have access...
  -> exec { "create-stanza-${name}":
    command     => "pgbackrest --stanza=${name} stanza-create",
    refreshonly => true,
  }
  # ... but this will fix permissions
  -> file { [
    "/var/lib/pgbackrest/backup/${name}",
    "/var/lib/pgbackrest/archive/${name}",
    "/var/log/pgbackrest/${name}",
    "/var/lock/pgbackrest/${name}",
  ]:
    ensure  => 'directory',
    mode    => '0750',
    owner   => $username,
    group   => $username,
    require => User[$username],
  }
  # create a username for the sandbox
  user { $username:
    ensure     => present,
    system     => true,
    managehome => true,
  }
  # find back the username, we assume we're provided with a username that respect the prefix
  $shortname = regsubst($username, '^pgbackrest-', '')
  [ 'full', 'diff'].each | $kind | {
    systemd::unit_file { "pgbackrest-backup-${kind}@${shortname}.service":
      enable => false,
      active => false,
      target => "/etc/systemd/system/pgbackrest-backup-${kind}@.service",
    }
    systemd::unit_file { "pgbackrest-backup-${kind}@${shortname}.timer":
      enable => true,
      active => true,
      target => "/etc/systemd/system/pgbackrest-backup-${kind}@.timer",
    }
  }
  # TODO: missing:
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
      ensure_resource('file', "/etc/ssh/puppetkeys/${username}", { owner => 'root', mode  => '0444', })
    }
  }
}
