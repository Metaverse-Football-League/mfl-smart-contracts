import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This script returns a data representation of a specific pack template.
**/

pub fun main(templateID: UInt64): MFLPackTemplate.PackTemplateData? {

    return MFLPackTemplate.getPackTemplate(id: templateID)
    
}