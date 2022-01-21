import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"


pub fun main(templateID: UInt64): MFLPackTemplate.PackTemplateData? {

    return MFLPackTemplate.getPackTemplate(id: templateID)
    
}