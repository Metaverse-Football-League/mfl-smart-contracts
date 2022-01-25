import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This script returns a data representation of a pack template
  given a pack template id.
**/

pub fun main(templateID: UInt64): MFLPackTemplate.PackTemplateData? {

    return MFLPackTemplate.getPackTemplate(id: templateID)
    
}