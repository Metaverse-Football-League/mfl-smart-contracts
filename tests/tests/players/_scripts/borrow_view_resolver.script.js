export const BORROW_VIEW_RESOLVER = `
    import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
    import MFLPlayer from "../../../../contracts/players/MFLPlayer.cdc"
    
    pub fun main(address: Address, playerID: UInt64): &{MetadataViews.Resolver}  {
        let playerCollectionRef = getAccount(address).getCapability<&{MetadataViews.ResolverCollection}>(MFLPlayer.CollectionPublicPath).borrow()
            ?? panic("Could not borrow the collection reference")
        let nftRef = playerCollectionRef.borrowViewResolver(id: playerID)
        return nftRef
    }
` 