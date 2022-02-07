# Purchase Pack Workflow

## Transaction

Parameters:

Name     | Description
------   | ------
dropID   | Id of the drop
nbToMint | Number of packs to be purchased
amount   | Purchase amount 

The `purchase.tx.cdc` tx creates a Pack Collection if the account doesn't have one.

Then it withdraws the amount from the account's Vault.

Finally it calls the MFLDrop purchase function.

## Contract

**1. MFLDrop purchase function:**

Parameters:

Name          | Description
------        | ------
dropID        | Id of the drop
address       | Owner address
nbToMint      | Number of packs to be purchased
senderVault   | The owner vault containing the amount that was defined in the tx
recipientCap  | Public capability to the owner Pack Collection

This public function is in charge of checking if the drop exists. If so, `getDropRef` is first called to get a reference to this specific drop and then `mint` is called.

  
**2. MFLDrop mint function :**

Parameters: Same as (1) but without dropID param.

The purpose of this function to make a certain number of checks to validate upstream the minting of packs.
Here is the exhaustive list of verifications. We check that:
- the address is the same as the address of the recipientCap
- the drop is not closed
- the maximum of packs per address is not exceeded
- if the drop status is opened_whitelist:
  - the address is whitelisted
  - the maximum of packs per whitelisted address is not exceeded
- the senderVault has enough balance

If the above steps are validated, the MFLPack `mint` function is called (3) and returns a Pack Collection.

Then we deposit into the ownerVault the senderVault. We update the minters dictionary to keep track of the number of packs minted for each minter (address).
Finally we deposit the content of the Pack Collection using recipientCap.

**3. MFLPack mint function**
- MFL PackTemplate getPackTemplateMintIndex function is called (4)
- Pack mint process explained and return new Collection of Packs.
Parameters:

Name            | Description
------          | ------
packTemplateID  | Id of the packTemplate
address         | Owner address
nbToMint        | Number of packs to be purchased

The purpose on this function is first to call MFLPackTemplate `getPackTemplateMintIndex` to get the packTemplateMintIndex used for our randomness logic (more info in startingIndex.md file).
This value will be part of a Pack NFT, as well as the packTemplate id.

Then we create a Pack Collection which contains nbToMint packs and returns it.

**4. MFL PackTemplate getPackTemplateMintIndex function**

Parameters: Same as (3).

This function checks if the packTemplate supply is enough (given nbToMint). If yes, the packTemplateMintIndex is computed (with `increaseStartingIndex` function) and returned.
This randomness logic is fully explained in startingIndex.md file.


## Sequence diagram

![Alt](./purchasePackSchema.pdf)