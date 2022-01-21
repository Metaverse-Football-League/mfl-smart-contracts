import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

pub fun main(id: UInt64): MFLDrop.DropData? {
    return MFLDrop.getDrop(id: id)
}