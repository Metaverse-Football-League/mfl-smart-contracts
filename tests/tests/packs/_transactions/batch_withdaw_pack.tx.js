export const BATCH_WITHDRAW_PACK = `
import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

transaction(receiverAddr: Address, ids: [UInt64]) {
    let receiverRef: &{NonFungibleToken.CollectionPublic}
    let senderRef: &MFLPack.Collection

    prepare(acct: AuthAccount) {
        self.receiverRef = getAccount(receiverAddr).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow() ??  panic("Could not borrow receiver collection reference")
        self.senderRef = acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
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
`