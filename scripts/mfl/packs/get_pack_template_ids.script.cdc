import MFLPackTemplate from 0x8ebcbfd516b1da27

/** 
  This script returns an array of ids of all pack templates
  living in MFLPackTemplate contract.
**/

pub fun main(): [UInt64] {

    return MFLPackTemplate.getPackTemplatesIDs()
    
}