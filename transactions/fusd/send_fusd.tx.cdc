import FungibleToken from 0xf233dcee88fe0abe
import FUSD from 0x3c5959b568896393

/** 
  This tx sends an arbitray amount of FUSD
  to a receiver address.
**/

transaction(receiverAddress: Address, amount: UFix64) {

    let receiverVaultRef : &FUSD.Vault{FungibleToken.Receiver}
    let senderVaultRef : &FUSD.Vault{FungibleToken.Provider}
    
    prepare(acct: AuthAccount) {
        self.senderVaultRef = acct.borrow<&FUSD.Vault{FungibleToken.Provider}>(from: /storage/fusdVault) ?? panic("could not borrow sender FUSD vault ref")
        self.receiverVaultRef = getAccount(receiverAddress).getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver).borrow() ?? panic("could not borrow receiver FUSD vault ref")
    }

    execute {
        let vault <- self.senderVaultRef.withdraw(amount: amount)
        self.receiverVaultRef.deposit(from: <-vault)
    }
}
 