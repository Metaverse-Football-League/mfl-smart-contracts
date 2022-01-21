import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

pub fun main(): [UInt64] {
    return MFLDrop.getDropsIDs()
}