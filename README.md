# Migrationator

License: 2-clause BSD

Status: Development

The Migrationator is a two-clause BSD-licensed open source tool that
utilizes [GAM](https://github.com/jay0lee/GAM) to perform a complete
export of all account data held in Vault for all Vault-licensed users.

Currently supported exports:

* email as PST files
* Drive (somewhat untested--experimental support)

## Dependencies

* ZSH
* Python 3.6
* GAM installed as `GAM`

## Usage

First get the list of users:

```
$ bin/migrationator.zsh userlist -o /tmp/userlist.csv
```

Next, export the email of all users in the user list:

```
$ mkdir -p /tmp/migration
$ bin/migrationator.zsh email -i /tmp/userlist.csv -o /tmp/migration
```

To export Drive data for all users in the user list:

```
$ mkdir -p /tmp/migration
$ bin/migrationator.zsh drive -i /tmp/userlist.csv -o /tmp/migration
```
