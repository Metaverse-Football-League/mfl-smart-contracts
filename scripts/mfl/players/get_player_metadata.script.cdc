import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns a data representation of a player metadata
  given a player id.
**/

pub fun main(playerID: UInt64): MFLPlayer.PlayerMetadata? {
    return MFLPlayer.getPlayerMetadata(playerID: playerID)
}
