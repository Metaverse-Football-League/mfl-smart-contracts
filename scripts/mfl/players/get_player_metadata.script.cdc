import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

pub fun main(playerID: UInt64): MFLPlayer.PlayerMetadata? {
    return MFLPlayer.getPlayerMetadata(playerID: playerID)
}
