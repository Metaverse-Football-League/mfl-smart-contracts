import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This tx gives a pack template admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example allows the opening of packs).
**/

transaction(receiverAddress: Address) {

    let adminRootRef: auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &MFLAdmin.AdminProxy
    let packTemplateAdminClaimCap: Capability<auth(MFLPackTemplate.PackTemplateAdminAction) &MFLPackTemplate.PackTemplateAdmin>

    prepare(acct: auth(BorrowValue, IssueStorageCapabilityController) &Account) {
        self.adminRootRef = acct.storage.borrow<auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot>(
                from: MFLAdmin.AdminRootStoragePath
            ) ?? panic("Could not borrow AdminRoot ref")

        let receiverAccount = getAccount(receiverAddress)
        self.receveiverAdminProxyRef = receiverAccount.capabilities.borrow<&MFLAdmin.AdminProxy>(
                MFLAdmin.AdminProxyPublicPath
            ) ?? panic("Could not get receiver reference to the Admin Proxy")

        self.packTemplateAdminClaimCap = acct.capabilities.storage.issue<auth(MFLPackTemplate.PackTemplateAdminAction) &MFLPackTemplate.PackTemplateAdmin>(MFLPackTemplate.PackTemplateAdminStoragePath)
        
    }

    execute {
        let name = self.packTemplateAdminClaimCap.borrow()!.name
        self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.packTemplateAdminClaimCap)
    }
}
