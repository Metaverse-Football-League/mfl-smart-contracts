import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This script returns an array of ids of all packs living 
  in a specific collection.
**/

pub fun main(address: Address): [UInt64] {
    let packCollectionRef = getAccount(address).getCapability<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow()
        ?? panic("Could not borrow the collection reference")
    return packCollectionRef.getIDs()
}
