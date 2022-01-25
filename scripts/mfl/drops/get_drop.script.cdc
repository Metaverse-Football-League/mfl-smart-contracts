import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This script returns a data representation of a specific drop.
**/

pub fun main(id: UInt64): MFLDrop.DropData? {
    return MFLDrop.getDrop(id: id)
}