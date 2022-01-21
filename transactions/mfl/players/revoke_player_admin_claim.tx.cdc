import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

transaction(privatePath: PrivatePath) {

  prepare(acct: AuthAccount) {
    assert(acct.getCapability<&{MFLPlayer.PlayerAdminClaim}>(privatePath).check(), message: "Capability path does not exist")
    acct.unlink(privatePath)
  }

  execute {
  }
}
