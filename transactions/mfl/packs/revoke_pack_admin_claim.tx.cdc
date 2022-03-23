import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This tx revokes a pack admin claim capability by
  providing a private path identifying the capability that should be removed.
**/

transaction(privatePath: Path) {

  prepare(acct: AuthAccount) {
    let privateCapabilityPath = privatePath as? PrivatePath
    assert(acct.getCapability<&{MFLPack.PackAdminClaim}>(privateCapabilityPath!).check(), message: "Capability path does not exist")
    acct.unlink(privateCapabilityPath!)
  }

  execute {
  }
}
