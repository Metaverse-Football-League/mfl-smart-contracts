import NonFungibleToken from 0x1d7e57aa55817448
import MFLPlayer from 0x8ebcbfd516b1da27

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
