# configure a central repository to collect stanzas from other repositories
#
# TODO:
# monitoring (only in trixie, missing service file: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1087805)
class pgbackrest::repository (
  String[1] $server_collect_tag = "pgbackrest::server::${facts['networking']['fqdn']}",
  String[1] $repository_collect_tag = "pgbackrest::repository::${facts['networking']['fqdn']}",
  Boolean $manage_ssh = true,
  String[1] $base_directory = '/var/lib/pgbackrest',
) {
  include pgbackrest

  file { [
    $base_directory,
    "${base_directory}/archive",
    '/var/lock/pgbackrest',
  ]:
    ensure => directory,
    # make directory only "executable", to restrict enumeration of
    # other hosts and lateral movement
    mode   => '0751',
    # we explicitly don't purge here, to allow for polite retirements
  }
  # backup directory needs to be enumerable, unfortunately, otherwise
  # the `info` command fails.
  file { "${base_directory}/backup":
    ensure => directory,
    mode   => '0755',
  }
  # collect the server's configurations and SSH keys
  Pgbackrest::Repository::Stanza <<| tag == $server_collect_tag |>>

  if $manage_ssh {
    # export all SSH keys of pgbackrest-* users so that clients can
    # realize them and authorize those users back in
    if $facts['ssh_keys_users'] and $facts['ssh_keys_users'] {
      # select only SSH keys matching th pgbackrest-* prefix
      $pg_backrest_users = $facts['ssh_keys_users'].filter | $key, $value | { $key =~ 'pgbackrest-.*' }
      $client_pg_user = 'postgres'
      # export an SSH key for each user, pgbackrest::clients realize this resource
      $pg_backrest_users.each | $repository_pg_user, $ssh_keys | {
        # remove the 'line' key so we can pass the rest directly to the ssh_authorized_key resource
        $ssh_key_params = $ssh_keys['id_rsa.pub']
        $_ssh_key_params = $ssh_key_params.filter |$key, $value| { $key != 'line' and $key != 'comment' }
        @@ssh_authorized_key { "${repository_pg_user}@${facts['networking']['fqdn']}":
          tag     => "pgbackrest::client::${repository_pg_user}::${facts['networking']['fqdn']}",
          target  => "/etc/ssh/puppetkeys/${client_pg_user}",
          user    => 'root',
          options => [
            'restrict',
            'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }"',  #lint:ignore:single_quote_string_with_variables
          ],
          *       => $_ssh_key_params,
        }
      }
    }
  }
}
