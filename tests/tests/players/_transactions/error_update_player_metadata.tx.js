export const ERROR_UPDATE_PLAYER_METADATA = `
    import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

    /** 
        This tx tries to update a player metadata.
    **/

    pub fun transform(player: MFLPlayer.PlayerData ): MFLPlayer.PlayerData {
        player.metadata = { "fakeMetadata": "" }
        return player
    }

    transaction(playerID: UInt64) {

        execute {
            let player =  MFLPlayer.getPlayerData(id: playerID)
            player.map(transform)
        }
        
    }
`