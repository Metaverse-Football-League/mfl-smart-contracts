export const GET_PLAYER_ROYALTIES_VIEW = `
  import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
  import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
  
  /**
    This script returns the Royalties view
    given a collection address and a player id,
  **/
  
  access(all)
  fun main(address: Address, id: UInt64): MetadataViews.Royalties {
  
      let collection = getAccount(address)
        .capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
        ?? panic("Could not borrow a reference to MFLPlayer collection")
  
      let nft = collection.borrowViewResolver(id: id)!
  
      let view = nft!.resolveView(Type<MetadataViews.Royalties>())!
      let royaltiesView = view as! MetadataViews.Royalties
      return royaltiesView
  }
`
