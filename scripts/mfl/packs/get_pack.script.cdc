import MFLPack from "../../../contracts/packs/MFLPack.cdc"


pub fun main(address: Address, id: UInt64): MFLPack.PackData? {

    return MFLPack.getPack(address: address, id: id)
    
}