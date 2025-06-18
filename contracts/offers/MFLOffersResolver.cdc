import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MetadataViews from "../_libs/MetadataViews.cdc"
import Resolver from "../_libs/Resolver.cdc"
import ViewResolver from "../_libs/ViewResolver.cdc"

access(all) contract MFLOffersResolver {
    access(all) let PublicPath: PublicPath
    access(all) let StoragePath: StoragePath

    access(all) enum ResolverType: UInt8 {
        access(all) case NFT
        access(all) case Global
    }

    access(all) resource OfferResolver: Resolver.ResolverPublic {
        access(all) fun checkOfferResolver(
            item: &{NonFungibleToken.NFT, ViewResolver.Resolver},
            offerParamsString: {String:String},
            offerParamsUInt64: {String:UInt64},
            offerParamsUFix64: {String:UFix64}
        ): Bool {
            if let expiry = offerParamsUInt64["expiry"] {
                assert(expiry > UInt64(getCurrentBlock().timestamp), message: "offer is expired")
            }
            switch offerParamsString["resolver"]! {
                case ResolverType.NFT.rawValue.toString():
                    assert(item.id.toString() == offerParamsString["nftId"], message: "item NFT does not have specified ID")
                    return true
                case ResolverType.Global.rawValue.toString():
                    assert(item.getType().identifier == offerParamsString["nftType"], message: "item NFT does not have specified type")
                    return true
                default:
                    panic("Invalid Resolver on Offer: ".concat(offerParamsString["resolver"] ?? "unknown"))
            }
        }

    }

    access(all) fun createResolver(): @OfferResolver {
        return <-create OfferResolver()
    }

    access(all) fun getResolverCap(): Capability<&{Resolver.ResolverPublic}> {
        return self.account.capabilities.get<&{Resolver.ResolverPublic}>(MFLOffersResolver.PublicPath)
    }

    init() {
        let p = "OffersResolver".concat(self.account.address.toString())

        self.PublicPath = PublicPath(identifier: p)!
        self.StoragePath = StoragePath(identifier: p)!

        let resolver <- create OfferResolver()
        self.account.storage.save(<-resolver, to: self.StoragePath)
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&{Resolver.ResolverPublic}>(self.StoragePath),
            at: self.PublicPath
        )
    }
}
