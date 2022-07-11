import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns a data representation array of players
  given players ids.
**/

pub fun main(playersIds: [UInt64]): [MFLPlayer.PlayerData] {
    let playersData: [MFLPlayer.PlayerData] = []
    for id in playersIds {
        if let playerData = MFLPlayer.getPlayerData(id: id) {
            playersData.append(playerData)
        }
    }
    return playersData
}
