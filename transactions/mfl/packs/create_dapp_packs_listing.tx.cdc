import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import DapperUtilityCoin from "../../../contracts/_libs/DapperUtilityCoin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"

/** 
  For a Dapper user to be able to purchase a Pack NFT,  the transaction that creates the Listing transaction 
  needs to be different than the standard example so that Dapper users can pay for an NFT using off-chain payment methods, 
  such as Dapper Balance, credit cards, ACH, wires and/or cryptocurrencies on other chains
**/

transaction(saleItemIDs: [UInt64], saleItemPrice: UFix64) {
    let ducReceiver: Capability<&{FungibleToken.Receiver}>
    let packCollectionProvider: Capability<&MFLPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(acct: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let packCollectionProviderPrivatePath = /private/MFLPackCollectionProviderForNFTStorefront

        self.ducReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        assert(self.ducReceiver.borrow() != nil, message: "Missing or mis-typed DUC receiver")

        if !acct.getCapability<&MFLPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath)!.check() {
            acct.link<&MFLPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath, target: MFLPack.CollectionStoragePath)
        }

        self.packCollectionProvider = acct.getCapability<&MFLPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(packCollectionProviderPrivatePath)!
        assert(self.packCollectionProvider.borrow() != nil, message: "Missing or mis-typed MFLPack.Collection provider")

        self.storefront = acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")

        // Make sure these NFTs are not already listed for sale in this storefront.
        let existingOffers = self.storefront.getListingIDs()
        if existingOffers.length > 0 {
            for listingResourceID in existingOffers {
                let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}? = self.storefront.borrowListing(listingResourceID: listingResourceID)
                if listing != nil {
                    for saleItemID in saleItemIDs {
                        if listing!.getDetails().nftID == saleItemID && listing!.getDetails().nftType == Type<@MFLPack.NFT>(){
                            self.storefront.removeListing(listingResourceID: listingResourceID)
                            break
                        }
                    }
                }
            }
        }
    }

    execute {
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.ducReceiver,
            amount: saleItemPrice
        )
        for saleItemID in saleItemIDs {
            self.storefront.createListing(
                nftProviderCapability: self.packCollectionProvider,
                nftType: Type<@MFLPack.NFT>(),
                nftID: saleItemID,
                salePaymentVaultType: Type<@DapperUtilityCoin.Vault>(),
                saleCuts: [saleCut]
            )
        }
    }
}