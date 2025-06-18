import OffersV2 from "./OffersV2.cdc"
import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import Resolver from "./Resolver.cdc"
import Burner from "./Burner.cdc"

// DapperOffersV2
//
// Each account that wants to create offers for NFTs installs an DapperOffer
// resource and creates individual Offers for NFTs within it.
//
// The DapperOffer resource contains the methods to add, remove, borrow and
// get details on Offers contained within it.
//
access(all) contract DapperOffersV2 {

    access(all) entitlement Manager
    access(all) entitlement ProxyManager
    // DapperOffersV2
    // This contract has been deployed.
    // Event consumers can now expect events from this contract.
    //
    access(all) event DapperOffersInitialized()

    /// DapperOfferInitialized
    // A DapperOffer resource has been created.
    //
    access(all) event DapperOfferInitialized(DapperOfferResourceId: UInt64)

    // DapperOfferDestroyed
    // A DapperOffer resource has been destroyed.
    // Event consumers can now stop processing events from this resource.
    //
    access(all) event DapperOfferDestroyed(DapperOfferResourceId: UInt64)


    // DapperOfferPublic
    // An interface providing a useful public interface to a Offer.
    //
    access(all) resource interface DapperOfferPublic {
        // getOfferIds
        // Get a list of Offer ids created by the resource.
        //
        access(all) fun getOfferIds(): [UInt64]
        // borrowOffer
        // Borrow an Offer to either accept the Offer or get details on the Offer.
        //
        access(all) fun borrowOffer(offerId: UInt64): &{OffersV2.OfferPublic}?
        // cleanup
        // Remove an Offer
        //
        access(all) fun cleanup(offerId: UInt64)
        // addProxyCapability
        // Assign proxy capabilities (DapperOfferProxyManager) to an DapperOffer resource.
        //
        access(all) fun addProxyCapability(
            account: Address,
            cap: Capability<auth(ProxyManager) &DapperOffer>
        )
    }

    // DapperOfferManager
    // An interface providing a management interface for an DapperOffer resource.
    //
    access(all) resource interface DapperOfferManager {
        // createOffer
        // Allows the DapperOffer owner to create Offers.
        //
        access(Manager) fun createOffer(
            vaultRefCapability: Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>,
            nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            amount: UFix64,
            royalties: [OffersV2.Royalty],
            offerParamsString: {String:String},
            offerParamsUFix64: {String:UFix64},
            offerParamsUInt64: {String:UInt64},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
        ): UInt64
        // removeOffer
        // Allows the DapperOffer owner to remove offers
        //
        access(Manager | ProxyManager) fun removeOffer(offerId: UInt64)
    }

    // DapperOfferProxyManager
    // An interface providing removeOffer on behalf of an DapperOffer owner.
    //
    access(all) resource interface DapperOfferProxyManager {
        // removeOffer
        // Allows the DapperOffer owner to remove offers
        //
        access(Manager | ProxyManager) fun removeOffer(offerId: UInt64)
        // removeOfferFromProxy
        // Allows the DapperOffer proxy owner to remove offers
        //
        access(ProxyManager) fun removeOfferFromProxy(account: Address, offerId: UInt64)
    }


    // DapperOffer
    // A resource that allows its owner to manage a list of Offers, and anyone to interact with them
    // in order to query their details and accept the Offers for NFTs that they represent.
    //
    access(all) resource DapperOffer :DapperOfferManager, DapperOfferPublic, DapperOfferProxyManager {
        // The dictionary of Address to DapperOfferProxyManager capabilities.
        access(self) var removeOfferCapability: {Address:Capability<auth(ProxyManager) &DapperOffer>}
        // The dictionary of Offer uuids to Offer resources.
        access(self) var offers: @{UInt64:OffersV2.Offer}

        // addProxyCapability
        // Assign proxy capabilities (DapperOfferProxyManager) to an DapperOffer resource.
        //
        access(all) fun addProxyCapability(account: Address, cap: Capability<auth(ProxyManager) &DapperOffer>) {
            pre {
                cap != nil: "Invalid admin capability"
            }
            self.removeOfferCapability[account] = cap
        }

        // removeOfferFromProxy
        // Allows the DapperOffer proxy owner to remove offers
        //
        access(ProxyManager) fun removeOfferFromProxy(account: Address, offerId: UInt64) {
            pre {
                self.removeOfferCapability[account] != nil:
                    "Cannot remove offers until the token admin has deposited the account registration capability"
            }

            let adminRef = self.removeOfferCapability[account]!

            adminRef.borrow()!.removeOffer(offerId: offerId)
        }


        // createOffer
        // Allows the DapperOffer owner to create Offers.
        //
        access(Manager) fun createOffer(
            vaultRefCapability: Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>,
            nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            amount: UFix64,
            royalties: [OffersV2.Royalty],
            offerParamsString: {String:String},
            offerParamsUFix64: {String:UFix64},
            offerParamsUInt64: {String:UInt64},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
        ): UInt64 {
            let offer <- OffersV2.makeOffer(
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

            let offerId = offer.uuid
            let dummy <- self.offers[offerId] <- offer
            destroy dummy

            return offerId
        }

        // removeOffer
        // Remove an Offer that has not yet been accepted from the collection and destroy it.
        //
        access(Manager | ProxyManager) fun removeOffer(offerId: UInt64) {
            let offer <- self.offers.remove(key: offerId) ?? panic("missing offer")
            // offer.customDestroy()

            Burner.burn(<-offer)
        }

        // getOfferIds
        // Returns an array of the Offer resource IDs that are in the collection
        //
        access(all) view fun getOfferIds(): [UInt64] {
            return self.offers.keys
        }

        // borrowOffer
        // Returns a read-only view of the Offer for the given OfferID if it is contained by this collection.
        //
        access(all) view fun borrowOffer(offerId: UInt64): &{OffersV2.OfferPublic}? {
            if self.offers[offerId] != nil {
                return (&self.offers[offerId] as &{OffersV2.OfferPublic}?)!
            } else {
                return nil
            }
        }

        // cleanup
        // Remove an Offer *if* it has been accepted.
        // Anyone can call, but at present it only benefits the account owner to do so.
        // Kind purchasers can however call it if they like.
        //
        access(all) fun cleanup(offerId: UInt64) {
            pre {
                self.offers[offerId] != nil: "could not find Offer with given id"
            }
            let offer <- self.offers.remove(key: offerId)!
            assert(offer.getDetails().purchased == true, message: "Offer is not purchased, only admin can remove")

            Burner.burn(<-offer)
        }

        // constructor
        //
        init() {
            self.removeOfferCapability = {}
            self.offers <- {}
            // Let event consumers know that this storefront will no longer exist.
            emit DapperOfferInitialized(DapperOfferResourceId: self.uuid)
        }

        access(all) event ResourceDestroyed(
            id: UInt64 = self.uuid
        )
    }

    // createDapperOffer
    // Make creating an DapperOffer publicly accessible.
    //
    access(all) fun createDapperOffer(): @DapperOffer {
        return <-create DapperOffer()
    }

    access(all) let DapperOffersStoragePath: StoragePath
    access(all) let DapperOffersPublicPath: PublicPath

    init () {
        self.DapperOffersStoragePath = /storage/DapperOffersV2
        self.DapperOffersPublicPath = /public/DapperOffersV2

        emit DapperOffersInitialized()
    }
}
