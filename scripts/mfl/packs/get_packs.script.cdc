import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This script returns a data representation array of all packs
  living in a specific collection.
**/

pub fun main(address: Address): [MFLPack.PackData] {

    return MFLPack.getPacks(address: address)
    
}