import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns a data representation of a player
  given a collection address and a player id,
  following the Display View defined in the MedataViews contract.
**/

access(all)
struct PlayerNFT {
    access(all)
    let name: String

    access(all)
    let description: String

    access(all)
    let thumbnail: String

    access(all)
    let owner: Address

    access(all)
    let type: String

    init(
        name: String,
        description: String,
        thumbnail: String,
        owner: Address,
        nftType: String,
    ) {
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.owner = owner
        self.type = nftType
    }
}

access(all)
fun main(address: Address, id: UInt64): PlayerNFT {

    let collection = getAccount(address)
         .capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
         ?? panic("Could not borrow a reference to MFLPlayer collection")

    let nft = collection.borrowViewResolver(id: id)

    // Get the basic display information for this NFT
    let view = nft!.resolveView(Type<MetadataViews.Display>())!

    let display = view as! MetadataViews.Display

    let owner: Address = nft!.owner!.address
    let nftType = nft!.getType()

    return PlayerNFT(
        name: display.name,
        description: display.description,
        thumbnail: display.thumbnail.uri(),
        owner: owner,
        nftType: nftType.identifier,
    )
}
