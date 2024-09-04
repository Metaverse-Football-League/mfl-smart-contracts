import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx delete all capability controllers by path_
**/

transaction(path: StoragePath) {

  prepare(acct: auth(GetStorageCapabilityController) &Account) {
    let controllers = acct.capabilities.storage.getControllers(forPath: path)
    for controller in controllers {
        controller.delete()
    }
  }

  execute {
  }
}
