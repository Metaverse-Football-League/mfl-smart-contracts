import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This tx batch withdraws clubs NFTs and deposits them
  in another collection.
**/

transaction(receiverAddr: Address, ids: [UInt64]) {

    let receiverRef: &MFLClub.Collection
    let senderRef: auth(NonFungibleToken.Withdraw) &MFLClub.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.receiverRef = getAccount(receiverAddr).capabilities.borrow<&MFLClub.Collection>(MFLClub.CollectionPublicPath) ??  panic("Could not borrow receiver collection reference")
        self.senderRef = acct.storage.borrow<auth(NonFungibleToken.Withdraw) &MFLClub.Collection>(from: MFLClub.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
    }

    execute {
        let tokens <- self.senderRef.batchWithdraw(ids: ids)

        let ids = tokens.getIDs()

        for id in ids {
            self.receiverRef.deposit(token: <-tokens.withdraw(withdrawID: id))
        }
        destroy tokens
    }
}
