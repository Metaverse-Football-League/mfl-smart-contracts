import NFTStorefront from 0x4eb8a10cb9f87357

/* 
  This transaction removes a NFT listing from the user's storefront.
*/

transaction(listingResourceID: UInt64) {
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontManager}

    prepare(seller: AuthAccount) {
        self.storefront = seller.borrow<&NFTStorefront.Storefront{NFTStorefront.StorefrontManager}>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront.Storefront")
    }

    execute {
        self.storefront.removeListing(listingResourceID: listingResourceID)
    }
}