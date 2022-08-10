import NFTStorefront from "../../contracts/_libs/NFTStorefront.cdc"

/**
  This tx removes listings if they have been purchased.
**/

transaction(account: Address, start: Int, end: Int) {
    let storefrontRef: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listingsIds: [UInt64]
    
    prepare(acct: AuthAccount) {
        self.storefrontRef = getAccount(account)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )
            .borrow()
            ?? panic("Could not borrow public storefront from address")

        self.listingsIds = self.storefrontRef.getListingIDs().slice(from: start, upTo: end)
    }

    execute {
        for id in self.listingsIds {
            let listing = self.storefrontRef.borrowListing(listingResourceID: id)
            if listing!.getDetails().purchased == true {
                self.storefrontRef.cleanup(listingResourceID: id)
            }
        }
    }
}