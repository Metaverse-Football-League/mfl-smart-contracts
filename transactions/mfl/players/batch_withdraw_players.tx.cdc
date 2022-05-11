import NonFungibleToken from 0x1d7e57aa55817448
import MFLPlayer from 0x8ebcbfd516b1da27

/** 
  This tx batch withdraws players NFTs and deposits them
  in another collection.
**/

transaction(receiverAddr: Address, ids: [UInt64]) {

    let receiverRef: &{NonFungibleToken.CollectionPublic}
    let senderRef: &MFLPlayer.Collection

    prepare(acct: AuthAccount) {
        self.receiverRef = getAccount(receiverAddr).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow() ??  panic("Could not borrow receiver collection reference")
        self.senderRef = acct.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
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
