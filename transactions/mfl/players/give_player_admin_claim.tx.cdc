import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This tx gives a player admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example update players metadata).
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address, privatePath: Path) {

  let adminRootRef: &MFLAdmin.AdminRoot
  let receveiverAdminProxyRef: &{MFLAdmin.AdminProxyPublic}
  let playerAdminClaimCapability: Capability<&MFLPlayer.PlayerAdmin{MFLPlayer.PlayerAdminClaim}>

  prepare(acct: AuthAccount) {
    self.adminRootRef = acct.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
    let receiverAccount = getAccount(receiverAddress)
    self.receveiverAdminProxyRef = receiverAccount.getCapability<&{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath).borrow() ?? panic("Could not borrow AdminProxyPublic ref")
    let privateCapabilityPath = privatePath as? PrivatePath
    self.playerAdminClaimCapability = acct.link<&MFLPlayer.PlayerAdmin{MFLPlayer.PlayerAdminClaim}>(privateCapabilityPath!, target: MFLPlayer.PlayerAdminStoragePath) ?? panic("path already exists")
  }

  execute {
    let name = self.playerAdminClaimCapability.borrow()!.name
    self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.playerAdminClaimCapability)
  }
}
