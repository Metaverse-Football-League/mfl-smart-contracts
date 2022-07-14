import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This script returns an array of all the MFL players nfts for sale in a Storefront
**/

pub fun main(account: Address): [NFTStorefront.ListingDetails] {
    let storefrontRef = getAccount(account)
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public storefront from address")

    let listingsIDs = storefrontRef.getListingIDs()
    let playersListings: [NFTStorefront.ListingDetails] = []

    for listingsID in listingsIDs {
        if let listing = storefrontRef.borrowListing(listingResourceID: listingsID) {
            let listingDetails = listing.getDetails()
            if listingDetails.nftType == Type<@MFLPlayer.NFT>() && !listingDetails.purchased {
                playersListings.append(listingDetails)
            }
        }
    }

    return playersListings

}