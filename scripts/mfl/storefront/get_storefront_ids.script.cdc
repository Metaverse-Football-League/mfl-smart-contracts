import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"

/**
  This script returns an array of all the nft uuids for sale through a Storefront
**/

access(all)
fun main(address: Address): [UInt64] {
    let storefrontRef = getAccount(address).capabilities.borrow<&NFTStorefront.Storefront>(
            NFTStorefront.StorefrontPublicPath
        ) ?? panic("Could not borrow public storefront from address")

    return storefrontRef.getListingIDs()
}
