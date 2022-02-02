import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns a data representation of a player
  given a collection address, a player id and following the PlayerDataViewV1 view.
**/

pub fun main(address: Address, id: UInt64): MFLViews.PlayerDataViewV1 {

    let collection = getAccount(address)
        .getCapability(MFLPlayer.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowViewResolver(id: id)

    let view = nft.resolveView(Type<MFLViews.PlayerDataViewV1>())!

    let playerData = view as! MFLViews.PlayerDataViewV1
    
    return playerData
}