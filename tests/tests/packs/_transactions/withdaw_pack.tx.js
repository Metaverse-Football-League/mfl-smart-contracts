export const WITHDRAW_PACK = `
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

transaction(receiverAddr: Address, id: UInt64) {
    let receiverRef: &{MFLPack.CollectionPublic}
    let senderRef: &MFLPack.Collection

    prepare(acct: AuthAccount) {
        self.receiverRef = getAccount(receiverAddr).getCapability<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow() ??  panic("Could not borrow receiver collection reference")
        self.senderRef = acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
    }

    execute {
        let nft <- self.senderRef.withdraw(withdrawID: id)
        self.receiverRef.deposit(token: <- nft)
    }
}
`