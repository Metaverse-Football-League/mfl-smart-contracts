import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"


pub fun main(): [MFLPackTemplate.PackTemplateData] {

    return MFLPackTemplate.getPackTemplates()
    
}