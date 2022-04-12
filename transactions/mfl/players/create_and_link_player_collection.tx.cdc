import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This tx creates a Player NFT collection
  and exposes a public capability to interact with it. 
**/

transaction() {

    prepare(acct: AuthAccount) {
        if acct.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) == nil {
          let collection <- MFLPlayer.createEmptyCollection()
          acct.save(<-collection, to: MFLPlayer.CollectionStoragePath)
          acct.link<&MFLPlayer.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLPlayer.CollectionPublicPath, target: MFLPlayer.CollectionStoragePath)
        }
    }
    
}
