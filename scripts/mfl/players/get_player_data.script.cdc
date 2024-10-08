import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns a data representation of a player
  given a player id.
**/

access(all)
fun main(playerID: UInt64): MFLPlayer.PlayerData? {
    return MFLPlayer.getPlayerData(id: playerID)
}
