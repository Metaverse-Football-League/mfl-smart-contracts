export const WITHDRAW_PACK = `
    import NonFungibleToken from 0x1d7e57aa55817448
    import MFLPack from "../../../contracts/packs/MFLPack.cdc"

    transaction(receiverAddr: Address, id: UInt64) {
        let receiverRef: &{NonFungibleToken.CollectionPublic}
        let senderRef: &MFLPack.Collection

        prepare(acct: AuthAccount) {
            self.receiverRef = getAccount(receiverAddr).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow() ??  panic("Could not borrow receiver collection reference")
            self.senderRef = acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
        }

        execute {
            let nft <- self.senderRef.withdraw(withdrawID: id)
            self.receiverRef.deposit(token: <- nft)
        }
    }
`