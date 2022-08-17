import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"

/** 
  This script returns a data representation of a squad
  given a squad id.
**/

pub fun main(squadID: UInt64): MFLClub.SquadData? {
    return MFLClub.getSquadData(id: squadID)
}