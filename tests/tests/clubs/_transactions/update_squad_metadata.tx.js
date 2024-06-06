export const UPDATE_SQUAD_METADATA = `
    import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

    /** 
     This tx updates the metadata of a squad.
    **/

    transaction(squadID: UInt64, squadName: String, squadDescription: String) {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy
    
        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
            let squadAdminClaimRef = squadAdminClaimCap.borrow<auth(MFLClub.SquadAdminAction) &MFLClub.SquadAdmin>() ?? panic("Could not borrow SquadAdmin")

            let metadata : {String: AnyStruct} = {}

            metadata.insert(key: "name", squadName)
            metadata.insert(key: "description", squadDescription)

            squadAdminClaimRef.updateSquadMetadata(id: squadID, metadata: metadata)
        }
    }
`;
