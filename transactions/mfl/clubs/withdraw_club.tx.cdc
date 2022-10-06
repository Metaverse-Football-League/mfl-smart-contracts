import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This tx withdraws a club NFT and deposits it
  in another collection.
**/

transaction(receiverAddr: Address, clubID: UInt64) {

    let receiverRef: &{NonFungibleToken.CollectionPublic}
    let senderRef: &MFLClub.Collection

    prepare(acct: AuthAccount) {
        self.receiverRef = getAccount(receiverAddr).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLClub.CollectionPublicPath).borrow() ??  panic("Could not borrow receiver collection reference")
        self.senderRef = acct.borrow<&MFLClub.Collection>(from: MFLClub.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
    }

    execute {
        let nft <- self.senderRef.withdraw(withdrawID: clubID)
        self.receiverRef.deposit(token: <- nft)
    }
}
