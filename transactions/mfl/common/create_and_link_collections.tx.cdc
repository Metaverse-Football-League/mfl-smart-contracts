import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import MFLPlayer from "../../../contracts/packs/MFLPlayer.cdc"
import MFLClub from "../../../contracts/packs/MFLClub.cdc"

/**
  This tx creates all the collections needed for MFL
  and exposes public capabilities to interact with them.
**/

transaction() {

    prepare(acct: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability, UnpublishCapability) &Account) {
        if acct.storage.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) == nil {
            let collection <- MFLPack.createEmptyCollection(nftType: Type<@MFLPack.NFT>())
            acct.storage.save(<-collection, to: MFLPack.CollectionStoragePath)
        }
        let packCap = acct.capabilities.get<&MFLPack.Collection>(MFLPack.CollectionPublicPath)
        if packCap == nil || !packCap!.check() {
            acct.capabilities.unpublish(MFLPack.CollectionPublicPath)
            let collectionCap = acct.capabilities.storage.issue<&MFLPack.Collection>(MFLPack.CollectionStoragePath)
            acct.capabilities.publish(collectionCap, at: MFLPack.CollectionPublicPath)
        }


        if acct.storage.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) == nil {
            let collection <- MFLPlayer.createEmptyCollection(nftType: Type<@MFLPlayer.NFT>())
            acct.storage.save(<-collection, to: MFLPlayer.CollectionStoragePath)
        }
        let playerCap = acct.capabilities.get<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
        if playerCap == nil || !playerCap!.check() {
            acct.capabilities.unpublish(MFLPlayer.CollectionPublicPath)
            let collectionCap = acct.capabilities.storage.issue<&MFLPlayer.Collection>(MFLPlayer.CollectionStoragePath)
            acct.capabilities.publish(collectionCap, at: MFLPlayer.CollectionPublicPath)
        }

        if acct.storage.borrow<&MFLClub.Collection>(from: MFLClub.CollectionStoragePath) == nil {
            let collection <- MFLClub.createEmptyCollection(nftType: Type<@MFLClub.NFT>())
            acct.storage.save(<-collection, to: MFLClub.CollectionStoragePath)
        }
        let clubCap = acct.capabilities.get<&MFLClub.Collection>(MFLClub.CollectionPublicPath)
        if clubCap == nil || !clubCap!.check() {
            acct.capabilities.unpublish(MFLClub.CollectionPublicPath)
            let collectionCap = acct.capabilities.storage.issue<&MFLClub.Collection>(MFLClub.CollectionStoragePath)
            acct.capabilities.publish(collectionCap, at: MFLClub.CollectionPublicPath)
        }
    }

}
