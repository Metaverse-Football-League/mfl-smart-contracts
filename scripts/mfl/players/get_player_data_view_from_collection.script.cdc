import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"

/** 
  This script returns a data representation of a player
  given a collection address, a player id and following the PlayerDataViewV1 view
**/

pub fun main(address: Address, id: UInt64): MFLViews.PlayerDataViewV1 {
    let account = getAccount(address)

    let collection = account
        .getCapability(MFLPlayer.CollectionPublicPath)
        .borrow<&{MFLPlayer.CollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowPlayer(id: id)!

    // Get the basic display information for this NFT
    let view = nft.resolveView(Type<MFLViews.PlayerDataViewV1>())!

    let playerData = view as! MFLViews.PlayerDataViewV1
    
    // let owner: Address = nft.owner!.address
    // let nftType = nft.getType()

    return playerData
}