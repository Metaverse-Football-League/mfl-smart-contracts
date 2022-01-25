import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns a data representation of a player metadata
  given a collection address and a player id.
**/

pub fun main(address: Address, playerID: UInt64): MFLPlayer.PlayerMetadata? {
    let playerNFT = MFLPlayer.fetch(from: address, itemID: playerID)
    return playerNFT != nil ? playerNFT!.getMetadata() : nil
}
