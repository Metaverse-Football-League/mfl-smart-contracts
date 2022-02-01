export const BORROW_VIEW_RESOLVER = `
    import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
    import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
    import MFLPack from "../../../../contracts/packs/MFLPack.cdc"
    
    pub fun main(address: Address, packID: UInt64): &{MetadataViews.Resolver}  {
        let packCollectionRef = getAccount(address).getCapability<&{MetadataViews.ResolverCollection}>(MFLPack.CollectionPublicPath).borrow()
            ?? panic("Could not borrow the collection reference")
        let nftRef = packCollectionRef.borrowViewResolver(id: packID)
        return nftRef
    }
` 