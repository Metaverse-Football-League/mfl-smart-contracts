import MetadataViews from 0x1d7e57aa55817448
import MFLViews from 0x8ebcbfd516b1da27
import MFLPack from 0x8ebcbfd516b1da27

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

    let packsDatas: [MFLViews.PackDataViewV1] = []

    for id in ids {
      let nft = collection.borrowViewResolver(id: id)
      let view = nft.resolveView(Type<MFLViews.PackDataViewV1>())!
      let packData = view as! MFLViews.PackDataViewV1
      packsDatas.append(packData)
    }

    return packsDatas
}