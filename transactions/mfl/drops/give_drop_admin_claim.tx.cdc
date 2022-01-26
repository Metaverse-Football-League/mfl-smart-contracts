import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This tx gives a drop admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example set whitelisted addresses for a specific drop).
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address, privatePath: Path) {

    let adminRootRef: &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &{MFLAdmin.AdminProxyPublic}
    let dropAdminClaimCapability: Capability<&{MFLDrop.DropAdminClaim}>

    prepare(acct: AuthAccount) {
        self.adminRootRef = acct.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
        let receiverAccount = getAccount(receiverAddress)
        self.receveiverAdminProxyRef = receiverAccount.getCapability<&{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath).borrow() ?? panic("Could not borrow AdminProxyPublic ref")
        let privateCapabilityPath = privatePath as? PrivatePath
        self.dropAdminClaimCapability = acct.link<&{MFLDrop.DropAdminClaim}>(privateCapabilityPath!, target: MFLDrop.DropAdminStoragePath) ?? panic("path already exists")
    }

    execute {
        let name = self.dropAdminClaimCapability.borrow()!.name
        self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.dropAdminClaimCapability)
    }
}
