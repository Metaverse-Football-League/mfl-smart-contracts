import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"

/** 
  This tx revokes a squad admin claim capability by
  providing a private path identifying the capability that should be removed.
**/

transaction(privatePath: Path) {

  prepare(acct: AuthAccount) {
    let privateCapabilityPath = privatePath as? PrivatePath
    assert(acct.getCapability<&{MFLClub.SquadAdminClaim}>(privateCapabilityPath!).check(), message: "Capability path does not exist")
    acct.unlink(privateCapabilityPath!)
  }

  execute {
  }
}
