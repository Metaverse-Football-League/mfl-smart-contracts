import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../../contracts/core/MFLAdmin.cdc"

/** 
  This tx removes a competitionMembership from a squad.
**/

transaction(squadID: UInt64, competitionID: UInt64) {
    let adminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
    }

    execute {
        let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
        let squadAdminClaimRef = squadAdminClaimCap.borrow<&{MFLClub.SquadAdminClaim}>() ?? panic("Could not borrow SquadAdminClaim")

        squadAdminClaimRef.removeSquadCompetitionMembership(id: squadID, competitionID: competitionID)
    }
}