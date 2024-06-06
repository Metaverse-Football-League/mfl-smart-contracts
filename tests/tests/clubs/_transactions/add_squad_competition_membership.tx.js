export const ADD_SQUAD_COMPETITION_MEMBERSHIP = `
    import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
    import MFLAdmin from "../../../../contracts/core/MFLAdmin.cdc"

    /** 
     This tx adds a competitionMembership to a squad.
    **/

    transaction(
        squadID: UInt64,
        competitionID: UInt64,
        competitionMembershipDataName: String,
        competitionMembershipDataReward: UInt32
    ) {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
            let squadAdminClaimRef = squadAdminClaimCap.borrow<auth(MFLClub.SquadAdminAction) &MFLClub.SquadAdmin>() ?? panic("Could not borrow SquadAdmin")

            let competitionMembershipData: {String: AnyStruct} = {}
            competitionMembershipData.insert(key: "name", competitionMembershipDataName)
            competitionMembershipData.insert(key: "reward", competitionMembershipDataReward)

            squadAdminClaimRef.addSquadCompetitionMembership(id: squadID, competitionID: competitionID, competitionMembershipData: competitionMembershipData)
        }
    }
`;
