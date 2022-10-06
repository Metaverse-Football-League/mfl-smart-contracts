export const UPDATE_SQUAD_METADATA = `
    import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

    /** 
     This tx updates the metadata of a squad.
    **/

    transaction(squadID: UInt64, squadName: String, squadDescription: String) {
        let adminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
            let squadAdminClaimRef = squadAdminClaimCap.borrow<&{MFLClub.SquadAdminClaim}>() ?? panic("Could not borrow SquadAdminClaim")

            let metadata : {String: AnyStruct} = {}

            metadata.insert(key: "name", squadName)
            metadata.insert(key: "description", squadDescription)

            squadAdminClaimRef.updateSquadMetadata(id: squadID, metadata: metadata)
        }
    }
`;
