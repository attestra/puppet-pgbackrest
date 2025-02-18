# pgbackrest

This module provides configuration management of [pgBackRest](https://pgbackrest.org) - Reliable PostgreSQL Backup & Restore.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with pgbackrest](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module allows all pgBackRest configuration options to be set in Hiera data.

## Setup

### PostgresQL Repositories

If you are not managing the repos another way, this module can install the postgresql.org
release RPM and enable the repo for the version you choose.

Do not enable repo management when using
  [puppetlabs/postgresql](https://forge.puppet.com/puppetlabs/postgresql)'s `$manage_package_repo` option.
The two repo management classes are redundant and will conflict with each other.

```yaml
pgbackrest::manage_package_repo: true      # Boolean
pgbackrest::yumrepos::enable_version: 12   # Integer
```

If you leave the `enable_version` parameter undeclared, only the *common* repo will be enabled.
This is the correct choice if you are using a different upstream, such as the PostgresQL AppStream,
and only want the addon packages (like pgBackRest). This is the default behavior.

If you wish to prevent updates or to remove the release RPM, you can change:

```yaml
pgbackrest::yumrepos::release_rpm_ensure: 'absent'
```

This will naturally prevent installation or updates of pgBackRest.

## Usage

Simply adding the module to a profile is sufficient to install pgBackRest.

```ruby
include pgbackrest
```

Only include the main class. Do not directly include the subclasses,
as they are contained by the top-level class. Subclasses may be refactored without notice.

## Central repository setup

To configure backups to be shipped from multiple PostgreSQL servers to
a central server (called here a "repository"), use the
`pgbackrest::repository` class on the server and the
`pgbackrest::client` on the servers.

    class { 'pgbackrest::client':
      repository_fqdn => 'repository.example.com',
    }

Then on the `repository` server:

    include pgbackrest::repository

The way this works is as follows:

 1. Each client exports a `pgbackrest::repository::stanza` resource
    which manage a user, a SSH key, and a configuration snippet

 2. The repository server realizes those resources to allow the client
    to push WAL files

 3. The repository, in turn, exports the SSH keys associated to those
    users back to the clients

 4. The clients realize those resources to allow the repository to
    pull full backups from clients

SSH keys management depends on the built-in `ssh_authorized_key`
resource and the
[`puppet/ssh_keygen`](https://github.com/voxpupuli/puppet-ssh_keygen)
module.

The WAL archival requires changes on the PostgreSQL server (pgbackrest
client) side. If you are using the `postgresql::server` class from
[`puppetlabs/postgresql`](https://forge.puppet.com/modules/puppetlabs/postgresql), you would do something like this:

```puppet
class { 'postgresql::server':
  config_entries => {
    wal_level => 'replica',
    archive_command => "pgbackrest
    --stanza=${facts['networking']['fqdn']} archive-push %p",
  }
}
```

Or in Hiera:

```yaml
postgresql::server::config_entries:
  wal_level: 'replica'
  archive_command: 'pgbackrest --stanza=materculae.torproject.org archive-push %p'
```

Schedules are defined in Hiera, but be aware of [systemd issue
21166](https://github.com/systemd/systemd/issues/21166), which you will trip on if you rely on the default
configuration. By default, reboots of the repository server will
offset the run time of jobs significantly, sometimes delaying backups
to up to the randomization period (the `RandomizedDelaySec`, for
example, up to a month for a full backups).

A workaround is to define the schedule in each client, like this:

```puppet
$day_of_month = fqdn_rand(28) + 1 # 1-28
$day_of_week = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
][fqdn_rand(7)] # 0-6 means, Mon-Sun

# monthly full backups, weekly diffs, no incrementals
class { 'pgbackrest::client':
  schedules       => {
    'full' => {
      'OnCalendar'         => "*-*-${day_of_month} 00:00:00",
      'RandomizedDelaySec' => '1d',
    },
    'diff' => {
      'OnCalendar'         => "${day_of_week} *-*-* 00:00:00",
      'RandomizedDelaySec' => '1d',
    },
    'incr' => {},
  }
}
```

## Limitations

Do not enable `manage_package_repo` when using
  [puppetlabs/postgresql](https://forge.puppet.com/puppetlabs/postgresql)'s `$manage_package_repo` option.
The two repo management classes are redundant.

## Development

Issues and Pull Requests happily accepted here.
