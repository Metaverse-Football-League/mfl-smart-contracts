import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/**
  This tx updates the status of a club.
**/

transaction(clubID: UInt64, statusRawValue: UInt8) {
    let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

    prepare(acct: auth(BorrowValue) &Account) {
        self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
    }

    execute {
        let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
        let clubAdminClaimRef = clubAdminClaimCap.borrow<auth(MFLClub.ClubAdminAction) &MFLClub.ClubAdmin>() ?? panic("Could not borrow ClubAdmin")

        let status = MFLClub.ClubStatus(rawValue: statusRawValue) ?? panic("invalid club status rawValue")

        clubAdminClaimRef.updateClubStatus(id: clubID, status: status)
    }
}
