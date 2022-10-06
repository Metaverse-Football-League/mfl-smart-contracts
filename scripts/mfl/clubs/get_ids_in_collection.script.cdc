import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This script returns an array of ids of all clubs
  living in a specific collection.
**/

pub fun main(address: Address): [UInt64] {
    let clubCollectionRef = getAccount(address).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLClub.CollectionPublicPath).borrow()
        ?? panic("Could not borrow a reference to MFLClub collection")
    return clubCollectionRef.getIDs()
}
