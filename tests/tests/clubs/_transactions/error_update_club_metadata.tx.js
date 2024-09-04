export const ERROR_UPDATE_CLUB_METADATA = `
    import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

    /** 
        This tx tries to update a club metadata.
    **/

    access(all)
    fun transform(club: MFLClub.ClubData ): MFLClub.ClubData {
        club.metadata = { "fakeMetadata": "" }
        return club
    }

    transaction(clubID: UInt64) {

        execute {
            let club =  MFLClub.getClubData(id: clubID)
            club.map(transform)
        }
        
    }
`
