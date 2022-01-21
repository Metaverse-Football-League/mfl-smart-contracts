import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import FUSD from "../../../contracts/_libs/FUSD.cdc"
import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

transaction(
  dropID: UInt64,
  nbToMint: UInt32,
  amount: UFix64,
) {
    let senderVault: &FUSD.Vault{FungibleToken.Provider}
    let address: Address
    let recipientCollectionCap: Capability<&{MFLPack.CollectionPublic}>

    prepare(acct: AuthAccount) {
      self.senderVault = acct.borrow<&FUSD.Vault{FungibleToken.Provider}>(from: /storage/fusdVault) ?? panic("Could not borrow fusd vault")
      self.address = acct.address
      fun hasPackCollection(address: Address): Bool {
        return getAccount(address)
        .getCapability<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath)
        .check()
      }

        
      if !hasPackCollection(address: self.address) {
        if acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) == nil {
          acct.save(<- MFLPack.createEmptyCollection(), to: MFLPack.CollectionStoragePath)
        }
        acct.unlink(MFLPack.CollectionPublicPath)
        acct.link<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath, target: MFLPack.CollectionStoragePath)
      }
      self.recipientCollectionCap = acct.getCapability<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath)
    }

    execute {

      let vault <- self.senderVault.withdraw(amount: amount)
      
      MFLDrop.purchase(
        dropID: dropID,
        address: self.address,
        nbToMint: nbToMint,
        senderVault: <-vault,
        recipientCap: self.recipientCollectionCap
      )
    }
}