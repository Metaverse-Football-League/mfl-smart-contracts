import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/**
  This script returns a data representation array of packs
  given a collection address and following the PackDataViewV1 view.
**/

access(all)
fun main(address: Address): [MFLViews.PackDataViewV1] {

    let collection = getAccount(address)
         .capabilities.borrow<&MFLPack.Collection>(MFLPack.CollectionPublicPath)
         ?? panic("Could not borrow a reference to MFLPack collection")

    let ids = collection!.getIDs()

    let packsDatas: [MFLViews.PackDataViewV1] = []

    for id in ids {
      let nft = collection!.borrowViewResolver(id: id)
      let view = nft!.resolveView(Type<MFLViews.PackDataViewV1>())!
      let packData = view as! MFLViews.PackDataViewV1
      packsDatas.append(packData)
    }

    return packsDatas
}
