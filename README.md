# Migrationator

License: 2-clause BSD

Status: Development

The Migrationator is a two-clause BSD-licensed open source tool that
utilizes [GAM](https://github.com/jay0lee/GAM) to perform a complete
export of all account data held in Vault for all Vault-licensed users.

Currently supported exports:

* email as PST files
* Drive as zip files

## Dependencies

* ZSH
* Python 3.6
* GAM installed as `GAM`
  * Optionally specify `-g /path/to/alternate/gam.py` as a global
    command-line option.
  * IMPORTANT: Make sure to perform the initial GAM setup prior to
    using the Migrationator.

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

## Development

The directory structure follows a heirarchy similar to a root
filesystem. Library code goes in `lib/migrationator` while the
application code resides in `bin`.

The Migrationator takes a verb as an argument. As of this writing, the
current supported verbs are:

1. drive
1. email
1. userlist

Verbs are modular and reside in `lib/migrationator/verbs`. Adding a
new verb is as easy as performing the following steps:

1. Adding the verb to the `lib/migrationator/util.zsh:sanity_checks`
   whitelist.
1. Adding the verb's code to the `lib/migrationator/verbs` directory.
   Filename format: ${VERBNAME}.zsh. For example, a hypothetical
   `calendar` verb's code would reside in the
   `lib/migrationator/verbs/calendar.zsh` file.
1. Implementing required functions.

Each verb must implement the following functions:

1. `${VERBNAME}_need_matter`: Return 1 if a Google Vault Matter should
   be opened, 0 otherwise.
1. `${VERBNAME}_run`: Execute the verb

Verbs can use any function in `lib/migrationator/*.zsh`. Verbs must
not rely on other verbs. Each verb is lazily-loaded based on
command-line arguments.
