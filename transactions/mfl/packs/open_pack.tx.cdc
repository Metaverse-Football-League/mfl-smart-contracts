import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/**
  This tx opens a pack, this will burn it and emit an event catched by the MFL backend to distribute the pack content.
  This will also create a player Collection (if the account doesn't have one).
 **/
 
 transaction(revealID: UInt64) {
    prepare(owner: AuthAccount) {
        let collectionRef = owner.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath)!
        collectionRef.openPack(id: revealID)
    }
}