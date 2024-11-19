# configure a central repository to collect stanzas from other repositories
#
# TODO:
# monitoring (only in trixie, missing service file: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1087805)
class pgbackrest::repository (
  String[1] $collect_tag = "pgbackrest::repository::${facts['networking']['fqdn']}",
) {
  include pgbackrest

  Pgbackrest::Repository::Stanza <<| tag == $collect_tag |>>
}
