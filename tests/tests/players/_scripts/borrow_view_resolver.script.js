export const BORROW_VIEW_RESOLVER = `
    import ViewResolver from "../../../contracts/_libs/ViewResolver.cdc"
    import MFLPlayer from "../../../../contracts/players/MFLPlayer.cdc"
    
    access(all)
    fun main(address: Address, playerID: UInt64): &{ViewResolver.Resolver}?  {
        let playerCollectionRef = getAccount(address).capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
            ?? panic("Could not borrow the collection reference")
        let nftRef = playerCollectionRef.borrowViewResolver(id: playerID)
        return nftRef
    }
`
