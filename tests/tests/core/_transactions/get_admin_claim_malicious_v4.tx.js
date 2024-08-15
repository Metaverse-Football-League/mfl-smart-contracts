export const GET_ADMIN_CLAIM_MALICIOUS_V4 = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

    transaction(adminAddr: Address) {
        prepare(acct: auth(BorrowValue) &Account) {
            getAccount(adminAddr).capabilities.storage.getControllers(forPath: MFLPlayer.PlayerAdminStoragePath)[0]!.capability.borrow<&MFLPlayer.PlayerAdmin>()
        }
        
        execute {
        }
    }
`;
