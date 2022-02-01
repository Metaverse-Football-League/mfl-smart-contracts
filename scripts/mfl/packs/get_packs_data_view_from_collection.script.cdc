import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This script returns a data representation array of packs
  given a collection address and following the PackDataViewV1 view.
**/

pub fun main(address: Address): [MFLViews.PackDataViewV1] {

    let collection = getAccount(address)
      .getCapability(MFLPack.CollectionPublicPath)
      .borrow<&{MetadataViews.ResolverCollection}>()
      ?? panic("Could not borrow a reference to the collection")

    let ids = collection.getIDs()

    let packs: [MFLViews.PackDataViewV1] = []

    for id in ids {
      let nft = collection.borrowViewResolver(id: id)
      let view = nft.resolveView(Type<MFLViews.PackDataViewV1>())!
      let packData = view as! MFLViews.PackDataViewV1
      packs.append(packData)
    }

    return packs
}