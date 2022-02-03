import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns a data representation array of players
  given a collection address and following the Display view defined in the MedataViews contract.
**/

pub struct PlayerNFT {
    pub let name: String
    pub let description: String
    pub let thumbnail: String
    pub let owner: Address
    pub let type: String

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

pub fun main(address: Address): [PlayerNFT] {

    let collection = getAccount(address)
        .getCapability(MFLPlayer.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to the collection")

    let players: [PlayerNFT] = []
    
    let ids = collection.getIDs()
    
    for id in ids {
        let nft = collection.borrowViewResolver(id: id)
        // Get the basic display information for this NFT
        let view = nft.resolveView(Type<MetadataViews.Display>())!
        let display = view as! MetadataViews.Display
        let owner: Address = nft.owner!.address
        let nftType = nft.getType()
        players.append(PlayerNFT(
            name: display.name,
            description: display.description,
            thumbnail: display.thumbnail.uri(),
            owner: owner,
            nftType: nftType.identifier,
            )
        )
    }

    return players
}
