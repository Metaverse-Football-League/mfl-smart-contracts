import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/** 
    This tx updates the club status and metadata in our central ledger (name, description)
    and set the club status to FOUNDED is isValid is true. Otherwise,
    it means that the validation of the name or description did not succeed
    and we have to reset the on chain metadata and set the club status to NOT_FOUNDED.
**/

transaction(
    clubID: UInt64,
    isValid: Bool
) {
    let adminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
    }

    execute {
        let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
        let clubAdminClaimRef = clubAdminClaimCap.borrow<&{MFLClub.ClubAdminClaim}>() ?? panic("Could not borrow ClubAdminClaim")
        if isValid {
            // Update the club status to founded
            clubAdminClaimRef.updateClubStatus(id: clubID, status: MFLClub.ClubStatus.FOUNDED)
        } else {
            // Clear all club metadata if validation was not approved // TODO do we want to clean all metadata (cf metadata init) ??
            clubAdminClaimRef.updateClubMetadata(id: clubID, metadata: {})
            // And update the club status to not founded
            clubAdminClaimRef.updateClubStatus(id: clubID, status: MFLClub.ClubStatus.NOT_FOUNDED)
        }
    }
}