export const GET_PACK_ROYALTIES_VIEW = `
  import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
  import MFLPack from "../../../contracts/packs/MFLPack.cdc"
  
  /**
    This script returns the Royalties view
    given a collection address and a pack id,
  **/
  
  pub fun main(address: Address, id: UInt64): MetadataViews.Royalties {
  
      let collection = getAccount(address)
          .getCapability(MFLPack.CollectionPublicPath)
          .borrow<&{MetadataViews.ResolverCollection}>()
          ?? panic("Could not borrow a reference to MFLPack collection")
  
      let nft = collection.borrowViewResolver(id: id)!
  
      let view = nft.resolveView(Type<MetadataViews.Royalties>())!
      let royaltiesView = view as! MetadataViews.Royalties
      return royaltiesView
  }
`
