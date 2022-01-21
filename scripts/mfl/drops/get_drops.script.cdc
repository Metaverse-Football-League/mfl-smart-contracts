import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

pub fun main(): [MFLDrop.DropData]? {
    return MFLDrop.getDrops()
}