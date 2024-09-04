import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns an array of ids of all clubs
  living in a specific collection.
**/

access(all)
fun main(address: Address): [UInt64] {
    let clubCollectionRef = getAccount(address).capabilities.borrow<&MFLClub.Collection>(
                MFLClub.CollectionPublicPath
            ) ?? panic("Could not get receiver reference to the NFT Collection")
    return clubCollectionRef.getIDs()
}
