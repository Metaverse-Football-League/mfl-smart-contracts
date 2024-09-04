import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns an array of ids of all players
  living in a specific collection.
**/

access(all)
fun main(address: Address): [UInt64] {
    let playerCollectionRef = getAccount(address).capabilities.borrow<&MFLPlayer.Collection>(
                MFLPlayer.CollectionPublicPath
            ) ?? panic("Could not get receiver reference to the NFT Collection")
    return playerCollectionRef.getIDs()
}

