import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/**
  This tx opens a pack, this will burn it and emit an event catched by the MFL backend to distribute the pack content.
**/

transaction(packID: UInt64) {
    prepare(acct: AuthAccount) {
        let collection = acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath)
        collection!.openPack(id: packID)
    }
}
