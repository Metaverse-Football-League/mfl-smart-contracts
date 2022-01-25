import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This script returns statuses of all drops.
**/

pub fun main(): {UInt64: MFLDrop.Status} {
    return MFLDrop.getDropsStatuses()
}
