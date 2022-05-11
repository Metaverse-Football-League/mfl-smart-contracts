import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import DapperUtilityCoin from 0xead892083b3e2c6c
import MFLPack from 0x8ebcbfd516b1da27
import NFTStorefront from 0x4eb8a10cb9f87357

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