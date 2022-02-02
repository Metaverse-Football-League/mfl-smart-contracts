import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns a data representation array of players
  given a collection address and following the PlayerDataViewV1 view.
**/

pub fun main(address: Address): [MFLViews.PlayerDataViewV1] {

    let collection = getAccount(address)
        .getCapability(MFLPlayer.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to the collection")

    let ids = collection.getIDs()

    let playersDatas: [MFLViews.PlayerDataViewV1] = []

    for id in ids {
        let nft = collection.borrowViewResolver(id: id)
        let view = nft.resolveView(Type<MFLViews.PlayerDataViewV1>())!
        let playerData = view as! MFLViews.PlayerDataViewV1
        playersDatas.append(playerData)
    }

    return playersDatas
}