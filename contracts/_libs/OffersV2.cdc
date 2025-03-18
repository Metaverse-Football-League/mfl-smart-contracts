import FungibleToken from "./FungibleToken.cdc"
import DapperUtilityCoin from "./DapperUtilityCoin.cdc"
import Resolver from "./Resolver.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ViewResolver from "./ViewResolver.cdc"
import Burner from "./Burner.cdc"

/// OffersV2
//
// Contract holds the Offer resource and a public method to create them.
//
// Each Offer can have one or more royalties of the sale price that
// goes to one or more addresses.
//
// Owners of NFT can watch for OfferAvailable events and check
// the Offer amount to see if they wish to accept the offer.
//
// Marketplaces and other aggregators can watch for OfferAvailable events
// and list offers of interest to logged in users.
//
access(all) contract OffersV2 {
    // OfferAvailable
    // An Offer has been created and added to the users DapperOffer resource.
    //

    access(all) event OfferAvailable(
        offerAddress: Address,
        offerId: UInt64,
        nftType: Type,
        offerAmount: UFix64,
        royalties: {Address:UFix64},
        offerType: String,
        offerParamsString: {String:String},
        offerParamsUFix64: {String:UFix64},
        offerParamsUInt64: {String:UInt64},
        paymentVaultType: Type,
        resolverType: String,
        paymentBorrowType: String
    )

    // OfferCompleted
    // The Offer has been resolved. The offer has either been accepted
    //  by the NFT owner, or the offer has been removed and destroyed.
    //
    access(all) event OfferCompleted(
        purchased: Bool,
        acceptingAddress: Address?,
        offerAddress: Address,
        offerId: UInt64,
        nftType: Type,
        offerAmount: UFix64,
        royalties: {Address:UFix64},
        offerType: String,
        offerParamsString: {String:String},
        offerParamsUFix64: {String:UFix64},
        offerParamsUInt64: {String:UInt64},
        paymentVaultType: Type,
        nftId: UInt64?,
    )

    // Royalty
    // A struct representing a recipient that must be sent a certain amount
    // of the payment when a NFT is sold.
    //
    access(all) struct Royalty {
        access(all) let receiver: Capability<&{FungibleToken.Receiver}>
        access(all) let amount: UFix64

        init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64) {
            self.receiver = receiver
            self.amount = amount
        }
    }

    // OfferDetails
    // A struct containing Offers' data.
    //
    access(all) struct OfferDetails {
        // The ID of the offer
        access(all) let offerId: UInt64
        // The Type of the NFT
        access(all) let nftType: Type
        // The Type of the FungibleToken that payments must be made in.
        access(all) let paymentVaultType: Type
        // The Offer amount for the NFT
        access(all) let offerAmount: UFix64
        // Flag to tracked the purchase state
        access(all) var purchased: Bool
        // This specifies the division of payment between recipients.
        access(all) let royalties: [Royalty]
        // Used to hold Offer metadata and offer type information
        access(all) let offerParamsString: {String: String}
        access(all) let offerParamsUFix64: {String:UFix64}
        access(all) let offerParamsUInt64: {String:UInt64}

        // setToPurchased
        // Irreversibly set this offer as purchased.
        //
        access(contract) fun setToPurchased() {
            self.purchased = true
        }

        // initializer
        //
        init(
            offerId: UInt64,
            nftType: Type,
            offerAmount: UFix64,
            royalties: [Royalty],
            offerParamsString: {String: String},
            offerParamsUFix64: {String:UFix64},
            offerParamsUInt64: {String:UInt64},
            paymentVaultType: Type,
        ) {
            self.offerId = offerId
            self.nftType = nftType
            self.offerAmount = offerAmount
            self.purchased = false
            self.royalties = royalties
            self.offerParamsString = offerParamsString
            self.offerParamsUFix64 = offerParamsUFix64
            self.offerParamsUInt64 = offerParamsUInt64
            self.paymentVaultType = paymentVaultType
        }
    }

    // OfferPublic
    // An interface providing a useful public interface to an Offer resource.
    //
    access(all) resource interface OfferPublic {
        // accept
        // This will accept the offer if provided with the NFT id that matches the Offer
        //
        access(all) fun accept(
            item: @{NonFungibleToken.NFT, ViewResolver.Resolver},
            receiverCapability: Capability<&{FungibleToken.Receiver}>,
        ): Void
        // getDetails
        // Return Offer details
        //
        access(all) fun getDetails(): OfferDetails
    }


    access(all) resource Offer: OfferPublic, Burner.Burnable {

        access(all)  event ResourceDestroyed(purchased: Bool = self.details.purchased, offerId: UInt64 = self.details.offerId)


        // The OfferDetails struct of the Offer
        access(self) let details: OfferDetails
        // The vault which will handle the payment if the Offer is accepted.
        access(contract) let vaultRefCapability: Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Provider, FungibleToken.Balance}>
        // Receiver address for the NFT when/if the Offer is accepted.
        access(contract) let nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>
        // Resolver capability for the offer type
        access(contract) let resolverCapability: Capability<&{Resolver.ResolverPublic}>

        init(
            vaultRefCapability: Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>,
            nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            amount: UFix64,
            royalties: [Royalty],
            offerParamsString: {String: String},
            offerParamsUFix64: {String:UFix64},
            offerParamsUInt64: {String:UInt64},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
        ) {
            pre {
                nftReceiverCapability.check(): "reward capability not valid"
                resolverCapability.check(): "invalid resolver capability"
            }
            self.vaultRefCapability = vaultRefCapability
            self.nftReceiverCapability = nftReceiverCapability
            self.resolverCapability = resolverCapability
            var price: UFix64 = amount
            let royaltyInfo: {Address:UFix64} = {}

            for royalty in royalties {
                assert(royalty.receiver.check(), message: "invalid royalty receiver")
                price = price - royalty.amount
                royaltyInfo[royalty.receiver.address] = royalty.amount
            }

            assert(price > 0.0, message: "price must be > 0")

            self.details = OfferDetails(
                offerId: self.uuid,
                nftType: nftType,
                offerAmount: amount,
                royalties: royalties,
                offerParamsString: offerParamsString,
                offerParamsUFix64: offerParamsUFix64,
                offerParamsUInt64: offerParamsUInt64,
                paymentVaultType: vaultRefCapability.getType(),
            )

            let resolver = self.resolverCapability.borrow() ?? panic("could not borrow resolver capability")
            emit OfferAvailable(
                offerAddress: nftReceiverCapability.address,
                offerId: self.details.offerId,
                nftType: self.details.nftType,
                offerAmount: self.details.offerAmount,
                royalties: royaltyInfo,
                offerType: offerParamsString["_type"] ?? "unknown",
                offerParamsString: self.details.offerParamsString,
                offerParamsUFix64: self.details.offerParamsUFix64,
                offerParamsUInt64: self.details.offerParamsUInt64,
                paymentVaultType: self.details.paymentVaultType,
                resolverType: resolver.getType().identifier,
                paymentBorrowType: self.vaultRefCapability.borrow()?.getType()?.identifier ?? "unknown"
            )
        }

        // accept
        // Accept the offer if...
        // - Calling from an Offer that hasn't been purchased/desetoryed.
        // - Provided with a NFT matching the NFT id within the Offer details.
        // - Provided with a NFT matching the NFT Type within the Offer details.
        //
        access(all) fun accept(
                item: @{NonFungibleToken.NFT, ViewResolver.Resolver},
                receiverCapability: Capability<&{FungibleToken.Receiver}>,
            ): Void {

            pre {
                !self.details.purchased: "Offer has already been purchased"
                item.isInstance(self.details.nftType): "item NFT is not of specified type"
            }

            let resolverCapability = self.resolverCapability.borrow() ?? panic("could not borrow resolver")
            let resolverResult = resolverCapability.checkOfferResolver(
                item: &item as &{NonFungibleToken.NFT, ViewResolver.Resolver},
                offerParamsString: self.details.offerParamsString,
                offerParamsUInt64: self.details.offerParamsUInt64,
                offerParamsUFix64: self.details.offerParamsUFix64,
            )

            if !resolverResult {
                panic("Resolver failed, invalid NFT please check Offer criteria")
            }

            self.details.setToPurchased()
            let nft <- item as! @{NonFungibleToken.NFT}
            let nftId: UInt64 = nft.id
            self.nftReceiverCapability.borrow()!.deposit(token: <- nft)

            let initalDucSupply = self.vaultRefCapability.borrow()!.balance
            let payment <- self.vaultRefCapability.borrow()!.withdraw(amount: self.details.offerAmount)

            // Payout royalties
            for royalty in self.details.royalties {
                if let receiver = royalty.receiver.borrow() {
                    let amount = royalty.amount
                    let part <- payment.withdraw(amount: amount)
                    receiver.deposit(from: <- part)
                }
            }

            receiverCapability.borrow()!.deposit(from: <- payment)

            // If a DUC vault is being used for payment we must assert that no DUC is leaking from the transactions.
            let isDucVault = self.vaultRefCapability.isInstance(
                Type<Capability<&DapperUtilityCoin.Vault>>()
            ) // todo: check if this is correct

            if isDucVault {
                assert(self.vaultRefCapability.borrow()!.balance == initalDucSupply, message: "DUC is leaking")
            }

            emit OfferCompleted(
                purchased: self.details.purchased,
                acceptingAddress: receiverCapability.address,
                offerAddress: self.nftReceiverCapability.address,
                offerId: self.details.offerId,
                nftType: self.details.nftType,
                offerAmount: self.details.offerAmount,
                royalties: self.getRoyaltyInfo(),
                offerType: self.details.offerParamsString["_type"] ?? "unknown",
                offerParamsString: self.details.offerParamsString,
                offerParamsUFix64: self.details.offerParamsUFix64,
                offerParamsUInt64: self.details.offerParamsUInt64,
                paymentVaultType: self.details.paymentVaultType,
                nftId: nftId,
            )
        }

        // getDetails
        // Return Offer details
        //
        access(all) view fun getDetails(): OfferDetails {
            return self.details
        }

        // getRoyaltyInfo
        // Return royalty details
        //
        access(all) view fun getRoyaltyInfo(): {Address:UFix64} {
            let royaltyInfo: {Address:UFix64} = {}

            for royalty in self.details.royalties {
                royaltyInfo[royalty.receiver.address] = royalty.amount
            }
            return royaltyInfo;
        }

        access(contract) fun burnCallback() {
            // Only emit the event if the offer has not been purchased; otherwise, the event has already been emitted
            if !self.details.purchased {
                emit OfferCompleted(
                    purchased: false,
                    acceptingAddress: nil,
                    offerAddress: self.nftReceiverCapability.address,
                    offerId: self.details.offerId,
                    nftType: self.details.nftType,
                    offerAmount: self.details.offerAmount,
                    royalties: self.getRoyaltyInfo(),
                    offerType: self.details.offerParamsString["_type"] ?? "unknown",
                    offerParamsString: self.details.offerParamsString,
                    offerParamsUFix64: self.details.offerParamsUFix64,
                    offerParamsUInt64: self.details.offerParamsUInt64,
                    paymentVaultType: self.details.paymentVaultType,
                    nftId: nil,
                )
            }
        }
    }

    // makeOffer
    access(all) fun makeOffer(
        vaultRefCapability:  Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>,
        nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
        nftType: Type,
        amount: UFix64,
        royalties: [Royalty],
        offerParamsString: {String:String},
        offerParamsUFix64: {String:UFix64},
        offerParamsUInt64: {String:UInt64},
        resolverCapability: Capability<&{Resolver.ResolverPublic}>,
    ): @Offer {
        let newOfferResource <- create Offer(
            vaultRefCapability: vaultRefCapability,
            nftReceiverCapability: nftReceiverCapability,
            nftType: nftType,
            amount: amount,
            royalties: royalties,
            offerParamsString: offerParamsString,
            offerParamsUFix64: offerParamsUFix64,
            offerParamsUInt64: offerParamsUInt64,
            resolverCapability: resolverCapability,
        )
        return <-newOfferResource
    }
}
