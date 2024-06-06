import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns a data representation of a club
  given a club id.
**/

access(all)
fun main(clubID: UInt64): MFLClub.ClubData? {
    return MFLClub.getClubData(id: clubID)
}
