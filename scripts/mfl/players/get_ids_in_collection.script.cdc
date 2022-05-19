import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns an array of ids of all players
  living in a specific collection.
**/

pub fun main(address: Address): [UInt64] {
    let playerCollectionRef = getAccount(address).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow()
        ?? panic("Could not borrow a reference to MFLPlayer collection")
    return playerCollectionRef.getIDs()
}
