export const BORROW_PACK = `
    import MFLPack from "../../../contracts/packs/MFLPack.cdc"

    pub fun main(address: Address, packID: UInt64): &MFLPack.NFT? {
        let packCollectionRef = getAccount(address).getCapability<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow()
            ?? panic("Could not borrow the collection reference")
        let packRef = packCollectionRef.borrowPack(id: packID)
        return packRef
    }
` 