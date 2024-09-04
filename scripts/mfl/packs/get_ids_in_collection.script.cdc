import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This script returns an array of ids of all packs living 
  in a specific collection.
**/

access(all)
fun main(address: Address): [UInt64] {
    let packCollectionRef = getAccount(address).capabilities.borrow<&MFLPack.Collection>(
                MFLPack.CollectionPublicPath
            ) ?? panic("Could not get receiver reference to the NFT Collection")
    return packCollectionRef.getIDs()
}
