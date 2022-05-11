import MFLPlayer from 0x8ebcbfd516b1da27

/** 
  This tx revokes a player admin claim capability by
  providing a private path identifying the capability that should be removed.
**/

transaction(privatePath: Path) {

  prepare(acct: AuthAccount) {
    let privateCapabilityPath = privatePath as? PrivatePath
    assert(acct.getCapability<&{MFLPlayer.PlayerAdminClaim}>(privateCapabilityPath!).check(), message: "Capability path does not exist")
    acct.unlink(privateCapabilityPath!)
  }

  execute {
  }
}
