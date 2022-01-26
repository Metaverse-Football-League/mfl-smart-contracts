import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This script returns a data representation array of all pack templates.
**/

pub fun main(): [MFLPackTemplate.PackTemplateData] {

    return MFLPackTemplate.getPackTemplates()
    
}