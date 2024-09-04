import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns a data representation array of players
  given a collection address, a list of players ids and following the PlayerDataViewV1 view.
**/

access(all)
fun main(address: Address, playersIds: [UInt64]): [MFLViews.PlayerDataViewV1] {

  let collection = getAccount(address)
       .capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
       ?? panic("Could not borrow a reference to MFLPlayer collection")

  let ids = collection!.getIDs()

  let playersDatas: [MFLViews.PlayerDataViewV1] = []

  for id in ids {
    let nft = collection!.borrowViewResolver(id: id)
    let view = nft!.resolveView(Type<MFLViews.PlayerDataViewV1>())!
    let playerData = view as! MFLViews.PlayerDataViewV1
    playersDatas.append(playerData)
  }

  return playersDatas
}
