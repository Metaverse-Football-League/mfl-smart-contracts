import MFLAdmin from "../../../../contracts/core/MFLAdmin.cdc"
import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"

/** 
  This tx gives a squad admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example mint squads).
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address, privatePath: Path) {
    let adminRootRef: &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &{MFLAdmin.AdminProxyPublic}
    let squadAdminClaimCapability: Capability<&{MFLClub.SquadAdminClaim}>

    prepare(acct: AuthAccount) {
        self.adminRootRef = acct.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
        let receiverAccount = getAccount(receiverAddress)
        self.receveiverAdminProxyRef = receiverAccount.getCapability<&{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath).borrow() ?? panic("Could not borrow AdminProxyPublic ref")
        let privateCapabilityPath = privatePath as? PrivatePath
        self.squadAdminClaimCapability = acct.link<&{MFLClub.SquadAdminClaim}>(privateCapabilityPath!, target: MFLClub.SquadAdminStoragePath) ?? panic("path already exists")
    }

    execute {
        let name = self.squadAdminClaimCapability.borrow()!.name
        self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.squadAdminClaimCapability)
    }
}
