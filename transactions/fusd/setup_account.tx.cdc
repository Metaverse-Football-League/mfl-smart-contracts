import FungibleToken from "../../contracts/_libs/FungibleToken.cdc"
import FUSD from "../../contracts/_libs/FUSD.cdc"

/** 
  This tx creates a FUSD vault in the storage and exposes
  public capabilities to be able to receive FUSD and get
  the actual balance.
**/

transaction() {
    
    prepare(acct: AuthAccount) {
        fun hasFUSD(_ address: Address): Bool {
            let receiver = getAccount(address).getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver).check()
            let balance = getAccount(address).getCapability<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance).check()
            return receiver && balance
        }
        if !hasFUSD(acct.address) {
            if acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil {
                acct.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
            }
            acct.unlink(/public/fusdReceiver)
            acct.unlink(/public/fusdBalance)
            acct.link<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver, target: /storage/fusdVault)
            acct.link<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance, target: /storage/fusdVault)
        }
    }

    execute {}
}