import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This tx gives a club admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example mint clubs).
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address) {

    let adminRootRef: auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &MFLAdmin.AdminProxy
    let clubAdminClaimCap: Capability<auth(MFLClub.ClubAdminAction) &MFLClub.ClubAdmin>

    prepare(acct: auth(BorrowValue, IssueStorageCapabilityController) &Account) {
     self.adminRootRef = acct.storage.borrow<auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot>(
             from: MFLAdmin.AdminRootStoragePath
         ) ?? panic("Could not borrow AdminRoot ref")

     let receiverAccount = getAccount(receiverAddress)
     self.receveiverAdminProxyRef = receiverAccount.capabilities.borrow<&MFLAdmin.AdminProxy>(
             MFLAdmin.AdminProxyPublicPath
         ) ?? panic("Could not get receiver reference to the Admin Proxy")

     self.clubAdminClaimCap = acct.capabilities.storage.issue<auth(MFLClub.ClubAdminAction) &MFLClub.ClubAdmin>(MFLClub.ClubAdminStoragePath)
    }

    execute {
     let name = self.clubAdminClaimCap.borrow()!.name
     self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.clubAdminClaimCap)
    }
}
