import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This script returns a data representation of a club
  given a club id.
**/

pub fun main(clubID: UInt64): MFLClub.ClubData? {
    return MFLClub.getClubData(id: clubID)
}
