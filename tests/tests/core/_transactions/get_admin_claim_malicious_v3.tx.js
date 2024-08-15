export const GET_ADMIN_CLAIM_MALICIOUS_V3 = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

    transaction(adminAddr: Address) {
        let adminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = getAccount(adminAddr).capabilities.borrow<&MFLAdmin.AdminProxy>(MFLAdmin.AdminProxyPublicPath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
            let playerAdminClaimCap = self.adminProxyRef.claimsCapabilities["PlayerAdminClaim"] ?? panic("PlayerAdminClaim capability not found")
        }
    }
`;
