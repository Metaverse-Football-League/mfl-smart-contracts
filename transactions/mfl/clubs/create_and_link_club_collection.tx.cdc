import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This tx creates a Club NFT collection
  and exposes a public capability to interact with it. 
**/

transaction() {

    prepare(acct: AuthAccount) {
        if acct.borrow<&MFLClub.Collection>(from: MFLClub.CollectionStoragePath) == nil {
          let collection <- MFLClub.createEmptyCollection()
          acct.save(<-collection, to: MFLClub.CollectionStoragePath)
          acct.link<&MFLClub.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLClub.CollectionPublicPath, target: MFLClub.CollectionStoragePath)
        }
    }
    
}
