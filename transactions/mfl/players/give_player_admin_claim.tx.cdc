import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx gives a player admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example mints players).
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address) {

    let adminRootRef: auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &MFLAdmin.AdminProxy
    let playerAdminClaimCap: Capability<auth(MFLPlayer.PlayerAdminAction) &MFLPlayer.PlayerAdmin>

    prepare(acct: auth(BorrowValue, IssueStorageCapabilityController) &Account) {
        self.adminRootRef = acct.storage.borrow<auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot>(
                from: MFLAdmin.AdminRootStoragePath
            ) ?? panic("Could not borrow AdminRoot ref")

        let receiverAccount = getAccount(receiverAddress)
        self.receveiverAdminProxyRef = receiverAccount.capabilities.borrow<&MFLAdmin.AdminProxy>(
                MFLAdmin.AdminProxyPublicPath
            ) ?? panic("Could not get receiver reference to the Admin Proxy")

        self.playerAdminClaimCap = acct.capabilities.storage.issue<auth(MFLPlayer.PlayerAdminAction) &MFLPlayer.PlayerAdmin>(MFLPlayer.PlayerAdminStoragePath)

    }

    execute {
        let name = self.playerAdminClaimCap.borrow()!.name
        self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.playerAdminClaimCap)
    }
}
