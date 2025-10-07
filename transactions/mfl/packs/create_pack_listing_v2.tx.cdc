import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import DapperUtilityCoin from "../../../contracts/_libs/DapperUtilityCoin.cdc"
import NFTStorefrontV2 from "../../../contracts/_libs/NFTStorefrontV2.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

transaction(
    saleItemID: UInt64,
    saleItemPrice: UFix64,
    royaltyPercent: UFix64,
    expiry: UInt64,
    royaltyAddress: Address
) {
  	let sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>
	let nftProviderCap: Capability<auth(NonFungibleToken.Withdraw) &MFLPack.Collection>
	let storefront: auth(NFTStorefrontV2.CreateListing, NFTStorefrontV2.RemoveListing) &NFTStorefrontV2.Storefront

    prepare(seller: auth(BorrowValue, CopyValue, LoadValue, SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {
     	// If the account doesn't already have a Storefront
		// Create a new empty Storefront
		if seller.storage.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) == nil {

			// Create a new empty Storefront
			let storefront <- NFTStorefrontV2.createStorefront() as! @NFTStorefrontV2.Storefront

			// save it to the account
			seller.storage.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)

			// create a public capability for the Storefront
			let storefrontPublicCap = seller.capabilities.storage.issue<&{NFTStorefrontV2.StorefrontPublic}>(
					NFTStorefrontV2.StorefrontStoragePath
				)
			seller.capabilities.publish(storefrontPublicCap, at: NFTStorefrontV2.StorefrontPublicPath)
		}

		// Get a reference to the receiver that will receive the fungible tokens if the sale executes.
		self.sellerPaymentReceiver = seller.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		assert(self.sellerPaymentReceiver.check(), message: "Missing or mis-typed DapperUtilityCoin receiver")

		// Get a capability to access the user's NFT collection.
		let nftProviderCapStoragePath: StoragePath = /storage/MFLPackCollectionCap
		let cap = seller.storage.copy<Capability<auth(NonFungibleToken.Withdraw) &MFLPack.Collection>>(from: nftProviderCapStoragePath)
		if cap != nil && cap!.check() {
			self.nftProviderCap = cap!
		} else {
			// clean this storage slot in case something is there already
			seller.storage.load<AnyStruct>(from: nftProviderCapStoragePath)
			self.nftProviderCap = seller.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &MFLPack.Collection>(MFLPack.CollectionStoragePath)
			seller.storage.save(self.nftProviderCap, to: nftProviderCapStoragePath)
		}
		assert(self.nftProviderCap.check(), message: "Missing or mis-typed collection provider")

		self.storefront = seller.storage.borrow<auth(NFTStorefrontV2.CreateListing, NFTStorefrontV2.RemoveListing) &NFTStorefrontV2.Storefront>(
                        from: NFTStorefrontV2.StorefrontStoragePath
                    ) ?? panic("Could not get a Storefront from the signer's account at path (NFTStorefrontV2.StorefrontStoragePath)!"
                                .concat("Make sure the signer has initialized their account with a NFTStorefrontV2 storefront!"))
    }

    execute {
    	let nftType = Type<@MFLPack.NFT>()
    	let salePaymentVaultType = Type<@DapperUtilityCoin.Vault>()

		let amountSeller = saleItemPrice * (1.0 - royaltyPercent)
		let saleCutSeller = NFTStorefrontV2.SaleCut(
			receiver: self.sellerPaymentReceiver,
			amount: amountSeller
		)

		// Get the royalty recipient's public account object
		let royaltyRecipient = getAccount(royaltyAddress)
		// Get a reference to the royalty recipient's Receiver
		let royaltyReceiverRef = royaltyRecipient.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		assert(royaltyReceiverRef.borrow() != nil, message: "Missing or mis-typed DapperUtilityCoin royalty receiver")
		let amountRoyalty = saleItemPrice - amountSeller
		let saleCutRoyalty = NFTStorefrontV2.SaleCut(
			receiver: royaltyReceiverRef,
			amount: amountRoyalty
		)

		// check for existing listings of the NFT
		var existingListingIDs = self.storefront.getExistingListingIDs(
			nftType: nftType,
			nftID: saleItemID
		)
		// remove existing listings
		for listingID in existingListingIDs {
			self.storefront.removeListing(listingResourceID: listingID)
		}

		// Create listing
		self.storefront.createListing(
			nftProviderCapability: self.nftProviderCap,
			nftType: nftType,
			nftID: saleItemID,
			salePaymentVaultType: salePaymentVaultType,
			saleCuts: [saleCutSeller, saleCutRoyalty],
			marketplacesCapability: nil,
			customID: nil,
			commissionAmount: 0.0,
			expiry: expiry
		)
    }
}
