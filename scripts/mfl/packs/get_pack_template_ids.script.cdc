import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This script returns an array of ids of all pack templates
  living in MFLPackTemplate contract.
**/

access(all)
fun main(): [UInt64] {
  return MFLPackTemplate.getPackTemplatesIDs()  
}