export const BATCH_WITHDRAW_PACK = `
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

transaction(receiverAddr: Address, ids: [UInt64]) {
    let receiverRef: &{MFLPack.CollectionPublic}
    let senderRef: &MFLPack.Collection

    prepare(acct: AuthAccount) {
        self.receiverRef = getAccount(receiverAddr).getCapability<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow() ??  panic("Could not borrow receiver collection reference")
        self.senderRef = acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
    }

    execute {
        let collection <- self.senderRef.batchWithdraw(ids: ids)
        self.receiverRef.batchDeposit(tokens: <- collection)
    }
}
`