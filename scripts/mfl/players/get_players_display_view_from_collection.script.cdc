import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns a data representation array of players
  given a collection address, a list of players ids and following the Display view defined in the MedataViews contract.
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
fun main(address: Address, playersIds: [UInt64]): [PlayerNFT] {

  let collection = getAccount(address)
                           .capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
                           ?? panic("Could not borrow a reference to MFLPlayer collection")

  let players: [PlayerNFT] = []

  let ids = collection.getIDs()

  for id in ids {
      let nft = collection.borrowViewResolver(id: id)
      // Get the basic display information for this NFT
      let view = nft!.resolveView(Type<MetadataViews.Display>())!
      let display = view as! MetadataViews.Display
      let owner: Address = nft!.owner!.address
      let nftType = nft!.getType()

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
