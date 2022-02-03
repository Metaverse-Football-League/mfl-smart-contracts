import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This script returns a data representation of a pack
  given a collection address, a pack id and following the PackDataViewV1 view.
**/

pub fun main(address: Address, id: UInt64): MFLViews.PackDataViewV1 {

    let collection = getAccount(address)
        .getCapability(MFLPack.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowViewResolver(id: id)

    let view = nft.resolveView(Type<MFLViews.PackDataViewV1>())!

    let packData = view as! MFLViews.PackDataViewV1

    return packData
}