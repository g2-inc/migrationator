# Migrationator

License: 2-clause BSD

Status: Proof-of-Concept

The Migrationator is a two-clause BSD-licensed open source tool that
utilizes [GAM](https://github.com/jay0lee/GAM) to perform a complete
export of all account data held in Vault for all Vault-licensed users
with mailboxes.

Development is currently done on HardenedBSD 12-STABLE. Since GAM is
not available as a port, yet, this script uses a custom installation
of GAM. The location of GAM is easy to be changed in the source.
Remember: this code is currently a PoC and is not yet ready for
production use.

## Dependencies

* ZSH
* Python 3.6 with pageexec and mprotect restrictions disabled
* GAM
