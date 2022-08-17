import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns a data representation array of clubs
  given clubs ids.
**/

pub fun main(clubsIds: [UInt64]): [MFLClub.ClubData] {
    let clubsDatas: [MFLClub.ClubData] = []
    for id in clubsIds {
        if let clubData = MFLClub.getClubData(id: id) {
            clubsDatas.append(clubData)
        }
    }
    return clubsDatas
}