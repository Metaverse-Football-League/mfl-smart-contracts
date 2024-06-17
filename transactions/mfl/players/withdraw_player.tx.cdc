import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx withdraws a specific player NFT and deposits it
  in another collection.
**/

transaction(receiverAddr: Address, id: UInt64) {

    let receiverRef: &MFLPlayer.Collection
    let senderRef: auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection

    prepare(acct: auth(BorrowValue) &Account) {
            self.receiverRef = getAccount(receiverAddr).capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath) ??  panic("Could not borrow receiver collection reference")
            self.senderRef = acct.storage.borrow<auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
    }

    execute {
        let nft <- self.senderRef.withdraw(withdrawID: id)
        self.receiverRef.deposit(token: <- nft)
    }
}
