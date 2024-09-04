export const ERROR_UPDATE_SQUAD_METADATA = `
    import MFLClub from "../../../contracts/squads/MFLClub.cdc"

    /** 
        This tx tries to update a squad metadata.
    **/

    access(all)
    fun transform(squad: MFLClub.SquadData ): MFLClub.SquadData {
        squad.metadata = { "fakeMetadata": "" }
        return squad
    }

    transaction(squadID: UInt64) {

        execute {
            let squad =  MFLClub.getSquadData(id: squadID)
            squad.map(transform)
        }
        
    }
`
