import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

transaction(
    clubID: UInt64,
    name: String,
    description: String
) {
    let adminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
    }

    execute {
        let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
        let clubAdminClaimRef = clubAdminClaimCap.borrow<&{MFLClub.ClubAdminClaim}>() ?? panic("Could not borrow ClubAdminClaim")
        let clubMetadata = MFLClub.getClubData(id: clubID)?.getMetadata() ?? panic("Data not found")
        clubMetadata.insert(key: "name", name)
        clubMetadata.insert(key: "description", description)
        clubAdminClaimRef.updateClubMetadata(id: clubID, metadata: clubMetadata)
        clubAdminClaimRef.updateClubStatus(id: clubID, status: MFLClub.Status.FOUNDED)
    }
}