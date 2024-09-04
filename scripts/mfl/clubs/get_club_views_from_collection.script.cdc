import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns an array of view types.
**/

access(all)
fun main(address: Address, id: UInt64): [Type] {

    let collection = getAccount(address)
        .capabilities.borrow<&MFLClub.Collection>(MFLClub.CollectionPublicPath)
        ?? panic("Could not borrow a reference to MFLClub collection")

    let nft = collection.borrowViewResolver(id: id)

    let viewTypes = nft!.getViews()

    return viewTypes
}
