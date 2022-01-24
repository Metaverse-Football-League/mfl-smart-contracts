import MFLPack from "../../../contracts/packs/MFLPack.cdc"


pub fun main(address: Address): [MFLPack.PackData] {

    return MFLPack.getPacks(address: address)
    
}