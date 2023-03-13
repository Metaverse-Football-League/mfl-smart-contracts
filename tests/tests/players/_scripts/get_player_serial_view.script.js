export const GET_PLAYER_SERIAL_VIEW = `
  import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
  import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
  
  /**
    This script returns the Serial view
    given a collection address and a player id,
  **/
  
  pub fun main(address: Address, id: UInt64): MetadataViews.Serial {
  
      let collection = getAccount(address)
          .getCapability(MFLPlayer.CollectionPublicPath)
          .borrow<&{MetadataViews.ResolverCollection}>()
          ?? panic("Could not borrow a reference to MFLPlayer collection")
  
      let nft = collection.borrowViewResolver(id: id)!
  
      let view = nft.resolveView(Type<MetadataViews.Serial>())!
      let serialView = view as! MetadataViews.Serial
      return serialView
  }
`
