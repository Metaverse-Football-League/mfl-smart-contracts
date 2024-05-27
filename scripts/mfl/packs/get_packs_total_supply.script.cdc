import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This script returns the total supply of packs.
**/

access(all)
fun main(): UInt64 {
    return MFLPack.totalSupply
}
