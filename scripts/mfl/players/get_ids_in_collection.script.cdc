import NonFungibleToken from 0x1d7e57aa55817448
import MFLPlayer from 0x8ebcbfd516b1da27

/** 
  This script returns an array of ids of all players
  living in a specific collection.
**/

pub fun main(address: Address): [UInt64] {
    let playerCollectionRef = getAccount(address).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow()
        ?? panic("Could not borrow the collection reference")
    return playerCollectionRef.getIDs()
}
