import FungibleToken from 0xf233dcee88fe0abe
import FUSD from 0x3c5959b568896393

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
