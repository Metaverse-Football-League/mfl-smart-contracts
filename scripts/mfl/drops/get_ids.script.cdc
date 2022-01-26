import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This script returns an array of drop ids.
**/

pub fun main(): [UInt64] {
    return MFLDrop.getDropsIDs()
}