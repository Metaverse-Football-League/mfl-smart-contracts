import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This script returns a data representation of a player
  given a collection address and a player id,
  following the Display View struct defined in the MedataViews contract
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

pub fun main(address: Address, id: UInt64): PlayerNFT {
    let account = getAccount(address)

    let collection = account
        .getCapability(MFLPlayer.CollectionPublicPath)
        .borrow<&{MFLPlayer.CollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowPlayer(id: id)!

    // Get the basic display information for this NFT
    let view = nft.resolveView(Type<MetadataViews.Display>())!

    let display = view as! MetadataViews.Display
    
    let owner: Address = nft.owner!.address
    let nftType = nft.getType()

    return PlayerNFT(
        name: display.name,
        description: display.description,
        thumbnail: display.thumbnail.uri(),
        owner: owner,
        nftType: nftType.identifier,
    )
}
