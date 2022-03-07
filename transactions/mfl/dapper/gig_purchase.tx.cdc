import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import DapperUtilityCoin from "../../../contracts/_libs/DapperUtilityCoin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

// This transaction takes a list of NFT IDs as an argument because there is no actual pack.
// It also passes metadata as an argument, because the lack of an on-chain pack means we have
// no good way of fetching pack metadata from the chain.
// The fact that we're taking important data through transaction arguments means it can easily
// be tampered with, so it's important that your dapp validates the transaction arguments before
// it signs this transction.
transaction(sellerAddress: Address, nftIDs: [UInt64], price: UFix64, metadata: {String: String}) {
    let yourAuthAccountAddress: Address
    let paymentVault: @FungibleToken.Vault
    let sellerPaymentReceiver: &{FungibleToken.Receiver}
    let yourNFTCollectionRef: @NonFungibleToken.Collection
    let buyerNFTCollection: &MFLPack.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}
    let balanceBeforeTransfer: UFix64
    let mainDucVault: &DapperUtilityCoin.Vault

    prepare(your: AuthAccount, dapper: AuthAccount, buyer: AuthAccount) {
        self.yourAuthAccountAddress = your.address

        // If the account doesn't already have a collection
        if buyer.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) == nil {
            // Create a new empty collection and save it to the account
            buyer.save(<-MFLPack.createEmptyCollection(), to: MFLPack.CollectionStoragePath)
            // Create a public capability to the MFLPack collection
            // that exposes the Collection interface
            buyer.link<&MFLPack.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
                MFLPack.CollectionPublicPath,
                target: MFLPack.CollectionStoragePath
            )
        }

        // withdraw NFT
        let yourNftProvider = your.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath)
            ?? panic("Could not borrow NFT Provider")
        self.yourNFTCollectionRef <- yourNftProvider.batchWithdraw(ids: nftIDs)

        // withdraw DUC
        self.mainDucVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
            ?? panic("Could not borrow reference to Dapper Utility Coin vault")
        self.balanceBeforeTransfer = self.mainDucVault.balance
        self.paymentVault <- self.mainDucVault.withdraw(amount: price)

        // set seller DUC receiver ref
        self.sellerPaymentReceiver = getAccount(sellerAddress).getCapability(/public/dapperUtilityCoinReceiver)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        // set buyer NFT receiver ref
        self.buyerNFTCollection = buyer
            .getCapability(MFLPack.CollectionPublicPath)!
            .borrow<&MFLPack.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>()!
    }

    // TODO Uncomment pre below to have the same template as Dapper, but i don't have 0xDUC_RECEIVER for now
    // pre {
    //     // Make sure the seller is the right account and that the DUC is going to the right place. We have to do this
    //     // because the NFTs are not being sold from a storefront listing with an attached DUC receiver.
    //     self.yourAuthAccountAddress == 0x704f29507f3446e5 && sellerAddress == 0xDUC_RECEIVER: "seller must be yourLabs"
    // }

    execute {
        self.sellerPaymentReceiver.deposit(from: <- self.paymentVault)
        let keys = self.yourNFTCollectionRef.getIDs()
        for key in keys {
            self.buyerNFTCollection.deposit(token: <-self.yourNFTCollectionRef.withdraw(withdrawID: key))
        }
        destroy self.yourNFTCollectionRef // TODO this line was not in the template, here for cadence linter
    }

    post {
        // Ensure there is no DUC leakage
        self.mainDucVault.balance == self.balanceBeforeTransfer: "transaction would leak DUC"
    }
}
