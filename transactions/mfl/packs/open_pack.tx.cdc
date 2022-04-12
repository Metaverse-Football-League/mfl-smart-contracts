import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx opens a pack, this will burn it and emit an event catched by the MFL backend to distribute the pack content.
  This will also create a player Collection (if the account doesn't have one).
 **/
 
 transaction(revealID: UInt64) {
    let collectionRef: &MFLPack.Collection

    prepare(owner: AuthAccount) {
        self.collectionRef = owner.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath)!
        if !owner.getCapability<&MFLPlayer.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLPlayer.CollectionPublicPath).check() {
            if owner.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) == nil {
                owner.save(<- MFLPlayer.createEmptyCollection(), to: MFLPlayer.CollectionStoragePath)
            }
            owner.unlink(MFLPlayer.CollectionPublicPath)
            owner.link<&MFLPlayer.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLPlayer.CollectionPublicPath, target: MFLPlayer.CollectionStoragePath)
        }
    }

    execute {
        self.collectionRef.openPack(id: revealID)
    }
}