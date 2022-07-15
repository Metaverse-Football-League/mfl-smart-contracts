import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns an array of all the MFL players nfts for sale in a Storefront.
  If the storefront does not exist, return an empty array
**/

pub struct ListingDetails {
    pub let listingResourceID: UInt64;
    pub let storefrontID: UInt64
    pub let purchased: Bool
    pub let nftType: Type
    pub let nftID: UInt64
    pub let salePaymentVaultType: Type
    pub let salePrice: UFix64
    pub let saleCuts: [NFTStorefront.SaleCut]

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

pub fun main(account: Address): [ListingDetails] {
    let storefrontRef = getAccount(account)
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        )
        .borrow()

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