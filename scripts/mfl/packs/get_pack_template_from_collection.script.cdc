import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

pub fun main(address: Address, packID: UInt64): MFLPackTemplate.PackTemplateData? {
     let packCollectionRef = getAccount(address).getCapability<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow()
        ?? panic("Could not borrow the collection reference")
    let packRef = packCollectionRef.borrowPack(id: packID)!
    return packRef.getPackTemplate()
}
