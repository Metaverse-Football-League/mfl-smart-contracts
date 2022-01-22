import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"


pub fun main(): [UInt64] {

    return MFLPackTemplate.getPackTemplatesIDs()
    
}