import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns a generic data representation of a player traits
  given a collection address and a player id,
  following the Traits View defined in the MedataViews contract.
**/

pub fun main(address: Address, id: UInt64): MetadataViews.Traits {

    let collection = getAccount(address)
        .getCapability(MFLPlayer.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to MFLPlayer collection")

    let nft = collection.borrowViewResolver(id: id)!

    // Get the basic display information for this NFT
    let view = nft.resolveView(Type<MetadataViews.Traits>())!

    let traitsView = view as! MetadataViews.Traits

    return traitsView
}
