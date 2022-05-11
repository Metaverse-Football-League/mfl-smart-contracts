import MFLPackTemplate from 0x8ebcbfd516b1da27

/** 
  This script returns a data representation array of all pack templates.
**/

pub fun main(): [MFLPackTemplate.PackTemplateData] {

    return MFLPackTemplate.getPackTemplates()
    
}