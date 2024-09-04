export const BORROW_VIEW_RESOLVER = `
    import ViewResolver from "../../../contracts/_libs/ViewResolver.cdc"
    import MFLPack from "../../../../contracts/packs/MFLPack.cdc"
    
    access(all)
    fun main(address: Address, packID: UInt64): &{ViewResolver.Resolver}?  {
        let packCollectionRef = getAccount(address).capabilities.borrow<&MFLPack.Collection>(MFLPack.CollectionPublicPath)
            ?? panic("Could not borrow the collection reference")
        let nftRef = packCollectionRef.borrowViewResolver(id: packID)
        return nftRef
    }
`
