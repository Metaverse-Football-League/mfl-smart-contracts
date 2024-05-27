import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx disables the storage capability
**/

transaction(path: StoragePath) {

  prepare(acct: auth(GetStorageCapabilityController) &Account) {
    let storageCapabilityController = acct.capabilities.storage.forEachController(byCapabilityID: capabilityID) ?? panic("No capability controller found")
    storageCapabilityController.delete()
  }

  execute {
  }
}
