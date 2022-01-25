import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This script returns ids array of all drops.
**/

pub fun main(): [UInt64] {
    return MFLDrop.getDropsIDs()
}