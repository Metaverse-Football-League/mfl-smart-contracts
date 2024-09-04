import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns a generic data representation of a club traits
  given a collection address and a club id,
  following the Traits View defined in the MedataViews contract.
**/

access(all)
fun main(address: Address, id: UInt64): MetadataViews.Traits {

    let collection = getAccount(address).capabilities.borrow<&MFLClub.Collection>(
           MFLClub.CollectionPublicPath
       ) ?? panic("Could not borrow the collection reference")

    let nft = collection.borrowViewResolver(id: id)!

    // Get the basic display information for this NFT
    let view = nft.resolveView(Type<MetadataViews.Traits>())!

    let traitsView = view as! MetadataViews.Traits

    return traitsView
}
