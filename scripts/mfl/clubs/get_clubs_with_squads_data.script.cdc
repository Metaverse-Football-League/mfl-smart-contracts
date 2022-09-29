import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns a data representation array of clubs including their squads' data,
  given clubs ids.
**/

pub struct ClubWithSquadData {
    pub var club: MFLClub.ClubData
    pub var squads: [MFLClub.SquadData]

    init(club: MFLClub.ClubData, squads: [MFLClub.SquadData]){
        self.club = club
        self.squads = squads
    }
}

pub fun main(clubsIds: [UInt64]): [ClubWithSquadData] {
    let res: [ClubWithSquadData] = []
    for id in clubsIds {
        if let clubData = MFLClub.getClubData(id: id) {
            let squadsData: [MFLClub.SquadData] = []
            for squadId in clubData.getSquadIDs() {
                if let squadData = MFLClub.getSquadData(id: squadId) {
                    squadsData.append(squadData)
                }
            }
            res.append(ClubWithSquadData(
                club: clubData,
                squads: squadsData,
            ))
        }
    }
    return res
}