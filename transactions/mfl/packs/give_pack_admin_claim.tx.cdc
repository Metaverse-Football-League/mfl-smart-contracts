import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This tx gives a pack admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example mints packs).
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address) {

    let adminRootRef: auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &MFLAdmin.AdminProxy
    let packAdminClaimCap: Capability<auth(MFLPack.PackAdminAction) &MFLPack.PackAdmin>

    prepare(acct: auth(BorrowValue, IssueStorageCapabilityController) &Account) {
        self.adminRootRef = acct.storage.borrow<auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot>(
                from: MFLAdmin.AdminRootStoragePath
            ) ?? panic("Could not borrow AdminRoot ref")

        let receiverAccount = getAccount(receiverAddress)
        self.receveiverAdminProxyRef = receiverAccount.capabilities.borrow<&MFLAdmin.AdminProxy>(
                MFLAdmin.AdminProxyPublicPath
            ) ?? panic("Could not get receiver reference to the Admin Proxy")

        self.packAdminClaimCap = acct.capabilities.storage.issue<auth(MFLPack.PackAdminAction) &MFLPack.PackAdmin>(MFLPack.PackAdminStoragePath)
        
    }

    execute {
        let name = self.packAdminClaimCap.borrow()!.name
        self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.packAdminClaimCap)
    }
}
