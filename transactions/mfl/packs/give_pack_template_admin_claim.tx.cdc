import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This tx gives a pack template admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example allows the opening of packs).
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address, privatePath: Path) {

    let adminRootRef: &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &{MFLAdmin.AdminProxyPublic}
    let packTemplateAdminClaimCapability: Capability<&{MFLPackTemplate.PackTemplateAdminClaim}>

    prepare(acct: AuthAccount) {
        self.adminRootRef = acct.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
        let receiverAccount = getAccount(receiverAddress)
        self.receveiverAdminProxyRef = receiverAccount.getCapability<&{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath).borrow() ?? panic("Could not borrow AdminProxyPublic ref")
        let privateCapabilityPath = privatePath as? PrivatePath
        self.packTemplateAdminClaimCapability = acct.link<&{MFLPackTemplate.PackTemplateAdminClaim}>(privateCapabilityPath!, target: MFLPackTemplate.PackTemplateAdminStoragePath) ?? panic("path already exists")
    }

    execute {
        let name = self.packTemplateAdminClaimCapability.borrow()!.name
        self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.packTemplateAdminClaimCapability)
    }
}
