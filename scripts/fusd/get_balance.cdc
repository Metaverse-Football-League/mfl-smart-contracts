import FungibleToken from "../../contracts/_libs/FungibleToken.cdc"
import FUSD from "../../contracts/_libs/FUSD.cdc"

/** 
  This script returns the balance of an account's FUSD vault.
  It will fail if the account does not have a FUSD vault.
**/

pub fun main(address: Address): UFix64 {
    let account = getAccount(address)

    let vaultRef = account.getCapability(/public/fusdBalance)
        .borrow<&FUSD.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
