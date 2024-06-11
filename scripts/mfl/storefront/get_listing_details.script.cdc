import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"

/**
  This script returns the details for a listing within a storefront
**/

access(all)
fun main(account: Address, listingResourceID: UInt64): NFTStorefront.ListingDetails {
    let storefrontRef = getAccount(address).capabilities.borrow<NFTStorefront.Storefront>(
                                    NFTStorefront.StorefrontPublicPath
                                ) ?? panic("Could not borrow public storefront from address")

    let listing = storefrontRef.borrowListing(listingResourceID: listingResourceID)
        ?? panic("No item with that ID")

    return listing.getDetails()
}
