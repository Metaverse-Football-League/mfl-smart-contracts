export const GET_PLAYER_METADATA_FOR_LISTING = `import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

access(all)
struct PurchaseData {

  access(all)
  let id: UInt64

  access(all)
  let name: String

  access(all)
  let amount: UFix64

  access(all)
  let description: String?

    access(all)
    let imageURL: String?

    init(id: UInt64, name: String, amount: UFix64, description: String?, imageURL: String?) {
    self.id = id
    self.name = name
    self.amount = amount
    self.description = description
    self.imageURL = imageURL
  }
}


access(all)
fun main(storefrontAddress: Address, listingResourceID: UInt64): PurchaseData {

  let account = getAccount(storefrontAddress)
  let marketCollectionRef = account.capabilities.borrow<&{NFTStorefront.StorefrontPublic}>(
    NFTStorefront.StorefrontPublicPath
  ) ?? panic("Could not borrow Storefront")

  let saleItem = marketCollectionRef.borrowListing(listingResourceID: listingResourceID)
?? panic("No item with that ID")

  let listingDetails = saleItem.getDetails()!

    let collection = account.capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
    ?? panic("Could not borrow a reference to the collection")

  let nft = collection.borrowViewResolver(id: listingDetails.nftID ) ?? panic("Could not borrow the view resolved")

  if let view = nft.resolveView(Type<MetadataViews.Display>()) {

    let display = view as! MetadataViews.Display

    let imageUrl = "https://d13e14gtps4iwl.cloudfront.net/players/v2/"

    let purchaseData = PurchaseData(
      id: listingDetails.nftID,
      name: display.name,
      amount: listingDetails.salePrice,
      description: display.description,
      imageURL: imageUrl.concat(listingDetails.nftID.toString()).concat("/card.png"),
  )

    return purchaseData
  }
  panic("No NFT")
}
`
