import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns a data representation array of squads
  given squads ids.
**/

pub fun main(squadsIds: [UInt64]): [MFLClub.SquadData] {
    let squadsDatas: [MFLClub.SquadData] = []
    for id in squadsIds {
        if let squadData = MFLClub.getSquadData(id: id) {
            squadsDatas.append(squadData)
        }
    }
    return squadsDatas
}