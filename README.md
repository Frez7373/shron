# SHRON

CC:Tweaked monitor for a Create Item Vault connected through a wired modem.

## Install

Run in CC:Tweaked:

```
wget run https://raw.githubusercontent.com/Frez7373/shron/main/install.lua
```

The installer downloads `vault.lua`.

## Start

```
vault
```

## What it shows

- used and total slots
- full stacks
- remaining loose items
- total item count

The program first tries to use the peripheral named `create:item_vault_0`. If it is not available, it falls back to the first peripheral of type `inventory`.

## Requirements

- CC:Tweaked
- Create Item Vault
- wired modem connection
- HTTP enabled for the installer
