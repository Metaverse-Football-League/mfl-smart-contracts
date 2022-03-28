import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This tx creates a Pack NFT collection
  and exposes a public capability to interact with it. 
**/

transaction() {

    prepare(acct: AuthAccount) {
        if acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) == nil {
          let collection <- MFLPack.createEmptyCollection()
          acct.save(<-collection, to: MFLPack.CollectionStoragePath)
          acct.link<&MFLPack.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLPack.CollectionPublicPath, target: MFLPack.CollectionStoragePath)
        }
    }
    
}
