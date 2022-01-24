import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

pub fun main(): {UInt64: MFLDrop.Status} {
    return MFLDrop.getDropsStatuses()
}
