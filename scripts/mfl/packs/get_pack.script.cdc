import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This script returns a data representation of a pack
  given a collection address and a pack id.
**/

pub fun main(address: Address, id: UInt64): MFLPack.PackData? {

    return MFLPack.getPack(address: address, id: id)
    
}