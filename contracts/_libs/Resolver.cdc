import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ViewResolver from "./ViewResolver.cdc"


// Resolver
//
// Contract holds the Offer exchange resolution rules.
//
// When an Offer is created a ResolverType is included. The ResolverType is also
// passed into checkOfferResolver() from the Offers contract on exchange validation
access(all) contract Resolver {
    // Current list of supported resolution rules.
    access(all) enum ResolverType: UInt8 {
        access(all) case NFT
        access(all) case MetadataViewsEditions
        access(all) case EditionIdAndSerialNumberTraits
    }

    // Public resource interface that defines a method signature for checkOfferResolver
    // which is used within the Resolver resource for offer acceptance validation
    access(all) resource interface ResolverPublic {
        access(all) fun checkOfferResolver(
            item: &{NonFungibleToken.NFT},
            offerParamsString: {String:String},
            offerParamsUInt64: {String:UInt64},
            offerParamsUFix64: {String:UFix64}
        ): Bool
    }


    // Resolver resource holds the Offer exchange resolution rules.
    access(all) resource OfferResolver: ResolverPublic {
        // checkOfferResolver
        // Holds the validation rules for resolver each type of supported ResolverType
        // Function returns TRUE if the provided nft item passes the criteria for exchange
        access(all) fun checkOfferResolver(
            item: &{NonFungibleToken.NFT},
            offerParamsString: {String:String},
            offerParamsUInt64: {String:UInt64},
            offerParamsUFix64: {String:UFix64}
        ): Bool {
            pre {
                offerParamsString.containsKey("resolver"): "offerParamsString must contain key 'resolver'"
            }
            switch offerParamsString["resolver"]! {
            case ResolverType.NFT.rawValue.toString():
                return Resolver.resolveNFTType(item, offerParamsString)
            case ResolverType.MetadataViewsEditions.rawValue.toString():
                return Resolver.resolveMetadataViewsEditionsType(item, offerParamsString)
            case ResolverType.EditionIdAndSerialNumberTraits.rawValue.toString():
                return Resolver.resolveEditionIdAndSerialNumberTraitsType(item, offerParamsString)
            default:
                panic("Invalid Resolver on Offer: ".concat(offerParamsString["resolver"]!))
            }
        }
    }

    // Resolves an offer for NFT type
    access(contract) fun resolveNFTType(_ item: &{NonFungibleToken.NFT}, _ offerParamsString: {String:String}): Bool {
        assert(item.id.toString() == offerParamsString["nftId"], message: "item NFT does not have specified ID")
        return true
    }

    // Resolves an offer for MetadataViewsEditions type
    access(contract) fun resolveMetadataViewsEditionsType(_ item: &{NonFungibleToken.NFT}, _ offerParamsString: {String:String}): Bool {
        let view = item.resolveView(Type<MetadataViews.Editions>())
            ?? panic("NFT does not use MetadataViews.Editions")
        let editions = view as! [MetadataViews.Edition]
        for edition in editions {
            if edition.name == offerParamsString["editionName"] {
                return true
            }
        }
        panic("no matching edition name for NFT")
    }

    // Resolves an offer for EditionIdAndSerialNumberTraits type
    access(contract) fun resolveEditionIdAndSerialNumberTraitsType(_ item: &{NonFungibleToken.NFT}, _ offerParamsString: {String:String}): Bool {
        pre {
            offerParamsString.containsKey("editionId"): "offerParamsString must contain key 'editionId'"
        }

        let view = item.resolveView(Type<MetadataViews.Traits>())
            ?? panic("NFT does not use MetadataViews.Traits")
        let traits = view as! MetadataViews.Traits

        let shouldValidateSerial = offerParamsString.containsKey("serialNumber")
        var hasValidEditionId = false
        var hasValidSerialNumber = false

        for trait in traits.traits {
            if trait.name.toLower() == "editionid" {
                if let nftEditionIdTrait = trait.value as! UInt64? {
                    hasValidEditionId = nftEditionIdTrait.toString() == offerParamsString["editionId"]
                }
            }
            if shouldValidateSerial && trait.name.toLower() == "serialnumber" {
                if let nftSerialNumber = trait.value as! UInt64? {
                    hasValidSerialNumber = nftSerialNumber.toString() == offerParamsString["serialNumber"]
                }
            }
            // Return early if the required traits are found and match
            if hasValidEditionId && (!shouldValidateSerial || hasValidSerialNumber) {
                return true
            }
        }
        return false
    }

    // Public function to create a new OfferResolver resource
    access(all) fun createResolver(): @OfferResolver {
        return <-create OfferResolver()
    }
}
