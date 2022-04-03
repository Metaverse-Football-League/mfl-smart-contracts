import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"

/** 
  This transaction installs the Storefront ressource in an account.
**/

transaction {
    prepare(acct: AuthAccount) {

        if acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) == nil {

            let storefront <- NFTStorefront.createStorefront()
            
            acct.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)

            acct.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath, target: NFTStorefront.StorefrontStoragePath)
        }
    }
}