import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

transaction(receiverAddr: Address, ids: [UInt64]) {

    let receiverRef: &{MFLPlayer.CollectionPublic}
    let senderRef: &MFLPlayer.Collection

    prepare(acct: AuthAccount) {
        self.receiverRef = getAccount(receiverAddr).getCapability<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow() ??  panic("Could not borrow receiver collection reference")
        self.senderRef = acct.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
    }

    execute {
        let collection <- self.senderRef.batchWithdraw(ids: ids)
        self.receiverRef.batchDeposit(tokens: <- collection)
    }
}
