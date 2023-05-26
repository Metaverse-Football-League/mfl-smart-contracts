import MetadataViews from 0x1d7e57aa55817448
import Flovatar from 0x921ea449dffec68a

pub fun main(address: Address, id: UInt64): MetadataViews.Royalties {

    let collection = getAccount(address)
        .getCapability(Flovatar.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to Flovatar collection")

    let nft = collection.borrowViewResolver(id: id)!

    // Get the basic display information for this NFT
    let view = nft.resolveView(Type<MetadataViews.Royalties>())!

    return view as! MetadataViews.Royalties
}
