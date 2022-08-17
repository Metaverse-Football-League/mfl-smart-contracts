import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This script returns an array of view types.
**/

pub fun main(address: Address, id: UInt64): [Type] {

    let collection = getAccount(address)
        .getCapability(MFLClub.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to MFLClub collection")

    let nft = collection.borrowViewResolver(id: id)

    let viewTypes = nft.getViews()

    return viewTypes
}