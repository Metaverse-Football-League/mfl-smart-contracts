import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns an array of all the MFL players nfts for sale in a Storefront.
  If the storefront does not exist, it returns an empty array.
**/

access(all)
struct ListingDetails {

    access(all)
    let listingResourceID: UInt64;

    access(all)
    let storefrontID: UInt64

    access(all)
    let purchased: Bool

    access(all)
    let nftType: Type

    access(all)
    let nftID: UInt64

    access(all)
    let salePaymentVaultType: Type

    access(all)
    let salePrice: UFix64

    access(all)
    let saleCuts: [NFTStorefront.SaleCut]

    init(_ storefrontListingDetails:NFTStorefront.ListingDetails, _ listingResourceId: UInt64) {
        self.listingResourceID = listingResourceId
        self.storefrontID = storefrontListingDetails.storefrontID
        self.purchased = storefrontListingDetails.purchased
        self.nftType = storefrontListingDetails.nftType
        self.nftID = storefrontListingDetails.nftID
        self.salePaymentVaultType = storefrontListingDetails.salePaymentVaultType
        self.salePrice = storefrontListingDetails.salePrice
        self.saleCuts = storefrontListingDetails.saleCuts
    }
}

access(all)
fun main(address: Address): [ListingDetails] {
    let storefrontRef = getAccount(address).capabilities.borrow<&NFTStorefront.Storefront>(
            NFTStorefront.StorefrontPublicPath
        )

    if storefrontRef == nil {
        return []
    }

    let listingsIDs = storefrontRef!.getListingIDs()
    let playersListings: [ListingDetails] = []

    for listingsID in listingsIDs {
        if let listing = storefrontRef!.borrowListing(listingResourceID: listingsID) {
            let storefrontListingDetails = listing.getDetails()
            if storefrontListingDetails.nftType == Type<@MFLPlayer.NFT>() && !storefrontListingDetails.purchased {
                playersListings.append(ListingDetails(storefrontListingDetails, listingsID))
            }
        }
    }

    return playersListings
}
