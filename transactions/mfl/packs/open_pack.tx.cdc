import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/**
  This tx opens a pack, this will burn it and emit an event catched by the MFL backend to distribute the pack content.
  This will also create a player Collection (if the account doesn't have one).
 **/

transaction(packID: UInt64) {
    prepare(acct: AuthAccount) {
        let collection = acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) ?? panic("Could not borrow pack Collection ref")
        //TODO player collection
        collection.openPack(id: packID)
    }
}
