import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"

/** 
  This script returns the total supply of squads.
**/

pub fun main(): UInt64 {
    return MFLClub.squadsTotalSupply
}