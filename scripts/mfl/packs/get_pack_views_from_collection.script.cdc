import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This script returns an array of view types.
**/

pub fun main(address: Address, id: UInt64): [Type] {

    let collection = getAccount(address)
        .getCapability(MFLPack.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to MFLPack collection")

    let nft = collection.borrowViewResolver(id: id)

    let viewTypes = nft.getViews()

    return viewTypes
}