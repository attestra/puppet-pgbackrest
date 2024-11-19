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

## Limitations

Do not enable `manage_package_repo` when using
  [puppetlabs/postgresql](https://forge.puppet.com/puppetlabs/postgresql)'s `$manage_package_repo` option.
The two repo management classes are redundant.

## Development

Issues and Pull Requests happily accepted here.
