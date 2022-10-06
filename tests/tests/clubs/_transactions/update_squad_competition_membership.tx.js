export const UPDATE_SQUAD_COMPETITION_MEMBERSHIP = `
    import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
    import MFLAdmin from "../../../../contracts/core/MFLAdmin.cdc"

    /** 
     This tx updates a competitionMembership to a squad.
    **/

    transaction(
        squadID: UInt64,
        competitionID: UInt64,
        competitionMembershipDataName: String,
        competitionMembershipDataReward: UInt32
    ) {
        let adminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
            let squadAdminClaimRef = squadAdminClaimCap.borrow<&{MFLClub.SquadAdminClaim}>() ?? panic("Could not borrow SquadAdminClaim")

            let competitionMembershipData: {String: AnyStruct} = {}
            competitionMembershipData.insert(key: "name", competitionMembershipDataName)
            competitionMembershipData.insert(key: "reward", competitionMembershipDataReward)

            squadAdminClaimRef.updateSquadCompetitionMembership(id: squadID, competitionID: competitionID, competitionMembershipData: competitionMembershipData)
        }
    }
`;
