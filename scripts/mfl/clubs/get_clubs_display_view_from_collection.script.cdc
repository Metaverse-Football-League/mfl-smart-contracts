import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns a data representation array of clubs
  given a collection address, a list of clubs ids and following the Display view defined in the MedataViews contract.
**/

access(all)
struct ClubNFT {

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
fun main(address: Address, clubsIds: [UInt64]): [ClubNFT] {

    let collection = getAccount(address).capabilities.borrow<&MFLClub.Collection>(
           MFLClub.CollectionPublicPath
       ) ?? panic("Could not borrow the collection reference")

    let clubs: [ClubNFT] = []

    for id in clubsIds {
        let nft = collection.borrowViewResolver(id: id)!
        // Get the basic display information for this NFT
        let view = nft.resolveView(Type<MetadataViews.Display>())!
        let display = view as! MetadataViews.Display
        let owner: Address = nft.owner!.address
        let nftType = nft.getType()
        clubs.append(ClubNFT(
            name: display.name,
            description: display.description,
            thumbnail: display.thumbnail.uri(),
            owner: owner,
            nftType: nftType.identifier,
            )
        )
    }

    return clubs
}
