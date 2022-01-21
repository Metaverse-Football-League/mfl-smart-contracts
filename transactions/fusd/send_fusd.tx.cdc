import FungibleToken from "../../contracts/_libs/FungibleToken.cdc"
import FUSD from "../../contracts/_libs/FUSD.cdc"

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