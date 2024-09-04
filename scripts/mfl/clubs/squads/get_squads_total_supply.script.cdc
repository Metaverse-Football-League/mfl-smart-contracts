import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns the total supply of squads.
**/

access(all)
fun main(): UInt64 {
    return MFLClub.squadsTotalSupply
}
