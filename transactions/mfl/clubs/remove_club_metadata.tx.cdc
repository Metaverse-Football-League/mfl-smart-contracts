import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/** 
  This tx removes the metadata of a club.
**/

transaction(clubID: UInt64, keysToRemove: [String]) {
    let adminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
    }

    execute {
        let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
        let clubAdminClaimRef = clubAdminClaimCap.borrow<&{MFLClub.ClubAdminClaim}>() ?? panic("Could not borrow ClubAdminClaim")

        clubAdminClaimRef.removeClubMetadata(id: clubID, keysToRemove: keysToRemove)
    }
}