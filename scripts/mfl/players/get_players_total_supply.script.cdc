import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns the total supply of players.
**/

access(all)
fun main(): UInt64 {
    return MFLPlayer.totalSupply
}
