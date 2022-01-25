import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This script returns a data representation of a drop
  given a drop id.
**/

pub fun main(id: UInt64): MFLDrop.DropData? {
    return MFLDrop.getDrop(id: id)
}