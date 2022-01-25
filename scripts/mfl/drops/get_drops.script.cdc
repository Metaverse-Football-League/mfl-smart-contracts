import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This script returns a data representation array
  of all drops.
**/

pub fun main(): [MFLDrop.DropData]? {
    return MFLDrop.getDrops()
}