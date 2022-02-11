# Metaverse Football League

## Introduction

This repository contains the smart contracts and transactions that implement
the core functionality of the Metaverse Football League (MFL).

The smart contracts are written in Cadence designed for the Flow Blockchain.

## Directory Structure

The directories here are organized into contracts, scripts, tests and transactions.

Contracts contain the source code for the MFL contracts that are deployed to Flow.

Scripts contain read-only transactions to get information about
the state of the MFL ecosystem.

Transactions contain the transactions that various admins and users can use
to perform actions in the smart contract like creating players, buying packs, ...

Tests contain the unit test for the contracts, transactions and scripts.

Tasks contain higher level scripts used for workflows needing multiple transactions / user inputs. Currently only used for scripts used to quickly
test the contracts, can be used for audits for example. 

## Contracts Overview

### MFLPlayer

Contract defining the player's resource and the collection used to store players. The contract also contains a central
ledger where all the players' metadata are stored. Allowing MFL admins to update them easily.

### MFLPack

Contract specifying the resource for packs and the collection used to store them. Each pack is a unique resource that
can be burned to open it and receive the associated resources after the opening event is processed off-chain.

### MFLPackTemplate

Contract used to store pack templates. A pack template defines common characteristics shared between multiples packs:
- a name for the packs
- an optional description of the packs
- maximum supply that can be purchased
- image used for the packs
- a flag indicating if packs' owners can open them or not

### MFLDrop

Contract handling drops. A drop allows users to buy packs. Each drop contain the configuration for how a pack is sold:
- the pack template used for the packs that are purchased
- the price of a pack
- the maximum number of packs allowed to be bought for a single address
- a potential list of whitelisted addresses that can be used to restrict who can purchase a pack
- the status of the drop, allowing the admin to open it to all, only to whitelisted or to close the drop

### MFLAdmin

Contract to access admin claims given by specific resources created for each contracts

### MFLViews

Contract that defines different structures representing different data. This contract is designed to meet the expectations of the new Flow metadata standard which is based on a view logic. Each view represents a different type of metadata.

## Tests

Tests are written with jest and the Flow js testing library. Our goal is to have the best test coverage possible. We try to test every lines / statements written in our smart contracts.

