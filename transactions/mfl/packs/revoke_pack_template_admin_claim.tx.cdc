import MFLPackTemplate from 0x8ebcbfd516b1da27

/** 
  This tx revokes a pack template admin claim capability by
  providing a private path identifying the capability that should be removed.
**/

transaction(privatePath: Path) {

  prepare(acct: AuthAccount) {
    let privateCapabilityPath = privatePath as? PrivatePath
    assert(acct.getCapability<&{MFLPackTemplate.PackTemplateAdminClaim}>(privateCapabilityPath!).check(), message: "Capability path does not exist")
    acct.unlink(privateCapabilityPath!)
  }

  execute {
  }
}
