import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This tx withdraws a specific player NFT and deposits it
  in another collection.
**/

transaction(receiverAddr: Address, id: UInt64) {

    let receiverRef: &{NonFungibleToken.CollectionPublic}
    let senderRef: &MFLPlayer.Collection

    prepare(acct: AuthAccount) {
        self.receiverRef = getAccount(receiverAddr).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow() ??  panic("Could not borrow receiver collection reference")
        self.senderRef = acct.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
    }

    execute {
        let nft <- self.senderRef.withdraw(withdrawID: id)
        self.receiverRef.deposit(token: <- nft)
    }
}
