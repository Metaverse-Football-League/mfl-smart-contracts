export const GET_CLUB_SERIAL_VIEW = `
  import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
  import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
  
  /**
    This script returns the Serial view
    given a collection address and a club id,
  **/
  
  pub fun main(address: Address, id: UInt64): MetadataViews.Serial {
  
      let collection = getAccount(address)
          .getCapability(MFLClub.CollectionPublicPath)
          .borrow<&{MetadataViews.ResolverCollection}>()
          ?? panic("Could not borrow a reference to MFLClub collection")
  
      let nft = collection.borrowViewResolver(id: id)!
  
      let view = nft.resolveView(Type<MetadataViews.Serial>())!
      let serialView = view as! MetadataViews.Serial
      return serialView
  }
`
