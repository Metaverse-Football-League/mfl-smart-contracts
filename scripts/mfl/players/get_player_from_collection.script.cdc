import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns a NFT player reference given
  a collection address and a player id.
**/

pub fun main(address: Address, playerID: UInt64): &MFLPlayer.NFT? {
    let playerCollectionRef = getAccount(address).getCapability<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow()
        ?? panic("Could not borrow the collection reference")
    let playerRef = playerCollectionRef.borrowPlayer(id: playerID)
    return playerRef
}
