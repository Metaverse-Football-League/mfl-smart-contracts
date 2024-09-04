import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/**
  This script returns a data representation of a pack
  given a collection address and a player id,
  following the Display view defined in the MedataViews contract.
**/

access(all)
struct PackNFT {
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
fun main(address: Address, id: UInt64): PackNFT {

    let collection = getAccount(address)
                             .capabilities.borrow<&MFLPack.Collection>(MFLPack.CollectionPublicPath)
                             ?? panic("Could not borrow a reference to MFLPack collection")

    let nft = collection.borrowViewResolver(id: id)

    // Get the basic display information for this NFT
    let view = nft!.resolveView(Type<MetadataViews.Display>())!

    let display = view as! MetadataViews.Display

    let owner: Address = nft!.owner!.address
    let nftType = nft!.getType()

    return PackNFT(
        name: display.name,
        description: display.description,
        thumbnail: display.thumbnail.uri(),
        owner: owner,
        nftType: nftType.identifier,
    )
}
