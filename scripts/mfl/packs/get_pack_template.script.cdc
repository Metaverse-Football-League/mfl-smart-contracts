import MFLPackTemplate from 0x8ebcbfd516b1da27

/** 
  This script returns a data representation of a specific pack template.
**/

pub fun main(templateID: UInt64): MFLPackTemplate.PackTemplateData? {

    return MFLPackTemplate.getPackTemplate(id: templateID)
    
}