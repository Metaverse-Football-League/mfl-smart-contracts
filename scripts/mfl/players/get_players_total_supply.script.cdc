import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns the total supply of players.
**/

pub fun main(): UInt64 {
    return MFLPlayer.totalSupply
}
