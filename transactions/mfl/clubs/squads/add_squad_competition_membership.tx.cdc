import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../../contracts/core/MFLAdmin.cdc"

/** 
  This tx adds a competitionMembership to a squad.
**/

 // ! TODO AnyStruct not valid in fcl arg
transaction(squadID: UInt64, competitionID: UInt64, competitionMembershipData: {String: AnyStruct}) {
    let adminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
    }

    execute {
        let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
        let squadAdminClaimRef = squadAdminClaimCap.borrow<&{MFLClub.SquadAdminClaim}>() ?? panic("Could not borrow SquadAdminClaim")

        squadAdminClaimRef.addSquadCompetitionMembership(id: squadID, competitionID: competitionID, competitionMembershipData: competitionMembershipData)
    }
}
 