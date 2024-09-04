export const GET_ADMIN_CLAIM_MALICIOUS = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

    transaction(adminAddr: Address) {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = getAccount(adminAddr).capabilities.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(MFLAdmin.AdminProxyPublicPath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
        }
    }
`;
