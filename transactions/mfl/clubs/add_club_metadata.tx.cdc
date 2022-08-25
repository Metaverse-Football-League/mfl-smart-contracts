import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/** 
  This tx adds the metadata of a club.
**/

 // ! TODO AnyStruct not valid in fcl arg - we have to define explicitly the metadata
transaction(clubID: UInt64, metadata: {String: AnyStruct}) {
    let adminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
    }

    execute {
        let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
        let clubAdminClaimRef = clubAdminClaimCap.borrow<&{MFLClub.ClubAdminClaim}>() ?? panic("Could not borrow ClubAdminClaim")

        clubAdminClaimRef.addClubMetadata(id: clubID, metadata: metadata)
    }
}