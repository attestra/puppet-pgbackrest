# configure a central repository to collect stanzas from other repositories
#
# TODO:
# monitoring (only in trixie, missing service file: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1087805)
class pgbackrest::repository (
  String[1] $server_collect_tag = "pgbackrest::server::${facts['networking']['fqdn']}",
  String[1] $repository_collect_tag = "pgbackrest::repository::${facts['networking']['fqdn']}",
  String[1] $pg_user = 'postgres',
  Boolean $manage_ssh = true,
) {
  include pgbackrest

  # collect the server's configurations and SSH keys
  Pgbackrest::Repository::Stanza <<| tag == $server_collect_tag |>>

  if $manage_ssh {
    # generate private key for the repository
    ssh::keygen { $pg_user: }
    # export private keys so that servers can allow it access
    if $facts['ssh_keys_users'] and $facts['ssh_keys_users'][$pg_user] and $facts['ssh_keys_users'][$pg_user]['id_rsa.pub'] {
      @@ssh_authorized_key { 'postgres':
        tag     => $repository_collect_tag,
        target  => '/etc/ssh/puppetkeys/postgres',
        user    => 'root',
        options => [
          'restrict',
          'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }"',  #lint:ignore:single_quote_string_with_variables
        ],
        #*       => $facts['ssh_keys_users'][$pg_user]['id_rsa.pub'], # XXX: can't do this because we also have ['line'] here
        key     => $facts['ssh_keys_users'][$pg_user]['id_rsa.pub']['key'],
        type    => $facts['ssh_keys_users'][$pg_user]['id_rsa.pub']['type'],
        comment => $facts['ssh_keys_users'][$pg_user]['id_rsa.pub']['comment'],
      }
    }
  }
}
