import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns an array of view types.
**/

access(all)
fun main(address: Address, id: UInt64): [Type] {

    let collection = getAccount(address)
        .capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
        ?? panic("Could not borrow a reference to MFLPlayer collection")

    let nft = collection.borrowViewResolver(id: id)

    let viewTypes = nft!.getViews()

    return viewTypes
}
