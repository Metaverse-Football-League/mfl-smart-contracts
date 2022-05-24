import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

pub struct PurchaseData {
    pub let id: UInt64
    pub let name: String
    pub let amount: UFix64
    pub let description: String?
    pub let imageURL: String?

    init(id: UInt64, name: String, amount: UFix64, description: String?, imageURL: String?) {
        self.id = id
        self.name = name
        self.amount = amount
        self.description = description
        self.imageURL = imageURL
    }
}

pub fun main(address: Address, listingResourceID: UInt64): PurchaseData {

    let account = getAccount(address)
    let marketCollectionRef = account
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        )
        .borrow()
        ?? panic("Could not borrow market collection from address")

    let saleItem = marketCollectionRef.borrowListing(listingResourceID: listingResourceID)
        ?? panic("No item with that ID")

    let listingDetails = saleItem.getDetails()!

    let collection = account.getCapability(MFLPack.CollectionPublicPath).borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowViewResolver(id: listingDetails.nftID )

    if let view = nft.resolveView(Type<MetadataViews.Display>()) {
        
        let display = view as! MetadataViews.Display

        let purchaseData = PurchaseData(
            id: listingDetails.nftID,
            name: display.name,
            amount: listingDetails.salePrice,
            description: display.description,
            imageURL: display.thumbnail.uri(),
        )
        
        return purchaseData
    }
    panic("No NFT")
}
    
