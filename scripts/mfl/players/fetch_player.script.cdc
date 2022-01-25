import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns a NFT player reference given
  a collection address and a player id.
**/

pub fun main(address: Address, playerID: UInt64): &MFLPlayer.NFT? {
    return MFLPlayer.fetch(from: address, itemID: playerID)
}
