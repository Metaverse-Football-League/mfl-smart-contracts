import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This tx creates a Club NFT collection
  and exposes a public capability to interact with it.
**/

transaction() {

     prepare(acct: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability, UnpublishCapability) &Account) {
        if acct.storage.borrow<&MFLClub.Collection>(from: MFLClub.CollectionStoragePath) == nil {
          let collection <- MFLClub.createEmptyCollection(nftType: Type<@MFLClub.NFT>())
          acct.storage.save(<-collection, to: MFLClub.CollectionStoragePath)

          acct.capabilities.unpublish(MFLClub.CollectionPublicPath)
          let collectionCap = acct.capabilities.storage.issue<&MFLClub.Collection>(MFLClub.CollectionStoragePath)
          acct.capabilities.publish(collectionCap, at: MFLClub.CollectionPublicPath)
        }
    }

}
