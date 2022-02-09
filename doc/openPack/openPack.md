# Open Pack Workflow

## Transaction

Parameters:

Name   | Description
------ | ------
packID | Id of the pack we want to open 

The `open_pack.tx.cdc` tx creates a Player Collection if the account doesn't have one.\

Then it calls the MFLPack `openPack` function with the specified packID.

## Contract

**1. MFLPack openPack function:**

Parameters:

Name   | Description
------ | ------
id     | Id of the pack we want to open

This function will first check that the corresponding pack is present in the collection.\
Then it will check if the packTemplate associated to the pack has its field `isOpenable` set to true.

At this point an event will be emitted with 4 parameters:

Name            | Description
------          | ------
id              | Id of the pack we want to open
packIndex       | Index of the pack for a corresponding packTemplate
packTemplateID  | Id of the packTemplate
from            | Address of the pack owner account

This event will be used in (2) for the off-chain logic part.\
Finally, the pack is burned in order not to be used again.

**2. Off-chain logic**

To catch the contract event defined previously, we use https://graffle.io/. In a nutshell, graffle is in charge of sending the events defined in (1) to our backend.\
We rely on AWS and its queue system (SQS) to handle these events as they happen.

We will use the startingIndex of the packTemplate (more info in startingIndex.md file) to distribute the content of the packs in a fair and random way.

## Sequence diagram

![Alt](./openPackDiagram.png)