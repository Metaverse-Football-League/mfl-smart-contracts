import NFTStorefront from 0x4eb8a10cb9f87357

/** 
  This script returns an array of all the nft uuids for sale through a Storefront
**/

pub fun main(account: Address): [UInt64] {
    let storefrontRef = getAccount(account)
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public storefront from address")
    
    return storefrontRef.getListingIDs()
}