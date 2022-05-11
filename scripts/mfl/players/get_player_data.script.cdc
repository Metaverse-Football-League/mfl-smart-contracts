import MFLPlayer from 0x8ebcbfd516b1da27

/** 
  This script returns a data representation of a player
  given a player id.
**/

pub fun main(playerID: UInt64): MFLPlayer.PlayerData? {
    return MFLPlayer.getPlayerData(id: playerID)
}
