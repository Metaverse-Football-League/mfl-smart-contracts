export const GET_CLUB_ROYALTIES_VIEW = `
  import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
  import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
  
  /**
    This script returns the Royalties view
    given a collection address and a club id,
  **/
  
  access(all)
  fun main(address: Address, id: UInt64): MetadataViews.Royalties {
  
      let collection = getAccount(address)
        .capabilities.borrow<&MFLClub.Collection>(MFLClub.CollectionPublicPath)
        ?? panic("Could not borrow a reference to MFLClub collection")
  
      let nft = collection.borrowViewResolver(id: id)!
  
      let view = nft!.resolveView(Type<MetadataViews.Royalties>())!
      let royaltiesView = view as! MetadataViews.Royalties
      return royaltiesView
  }
`
