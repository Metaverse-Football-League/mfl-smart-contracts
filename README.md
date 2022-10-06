# Metaverse Football League

## Introduction

This repository contains the smart contracts and transactions that implement
the core functionality of the Metaverse Football League (MFL).

The smart contracts are written in Cadence designed for the Flow Blockchain.

## Directory Structure

The directories here are organized into contracts, scripts, tests and transactions.

- Contracts contain the source code for the MFL contracts that are deployed to Flow.

- Scripts contain read-only transactions to get information about
the state of the MFL ecosystem.

- Transactions contain the transactions that various admins and users can use
to perform actions in the smart contract like creating players, buying packs, ...

- Tests contain the unit test for the contracts, transactions and scripts.


## Contracts Overview

### MFLPlayer

`/contracts/players/MFLPlayer.cdc`

Contract defining the player's resource and the collection used to store players. The contract also contains a central
ledger where all the players' metadata are stored. Allowing MFL admins to update them easily.

### MFLClub

`/contracts/clubs/MFLClub.cdc`

Contract defining the club's resource and the collection used to store them. The contract also contains a central
ledger where all the clubs' metadata are stored. Squads 

### MFLPack

`/contracts/packs/MFLPack.cdc`

Contract specifying the resource for packs and the collection used to store them. Each pack is a unique resource that
can be burned to open it and receive the associated resources after the opening event is processed off-chain (see `/doc/openPack.md` for more details).

### MFLPackTemplate

`/contracts/packs/MFLPackTemplate.cdc`

Contract used to store pack templates. A pack template defines common characteristics shared between multiples packs:
- a unique ID
- a name for the packs
- an optional description of the packs
- maximum supply (nb of packs that can be minted)
- current supply (nb of packs currently minted)
- a flag indicating if packs' owners can open them or not
- image used for the packs
- a type (Base, Rare, Legendary,...)
- slots containing details of the probability of having a specific type of player.
### MFLAdmin

`/contracts/core/MFLAdmin.cdc`

Contract to access admin claims given by specific resources created for each contracts.

To be able to perform some admin transactions (mint players, mint packs,...), an account must have claims. These claims are given by the root admin. This one will set a private capability in an `AdminProxy` resource (which must be present in the storage of the account receiving the capability).

At any time the root admin can decide to remove a capability for a given account.



### MFLViews

`/contracts/views/MFLView.cdc`

Contract that defines different structures representing different data. This contract is designed to meet the expectations of the new Flow metadata standard which is based on a view logic. Each view represents a different type of metadata.

## Tests

Tests are written with jest and the Flow js testing library. Our goal is to have the best test coverage possible. We try to test every lines / statements written in our smart contracts.


## Dapper transactions

As we plan to use the Dapper Wallet, we need to whitelist some transactions that will be initiated by users from our Dapp.

These transactions are available here: 
https://github.com/Metaverse-Football-League/mfl-dapper-transactions
