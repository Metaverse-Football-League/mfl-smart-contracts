export const CREATE_ADMIN_ROOT_MALICIOUS_V3 = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

    transaction(adminAddr: Address) {
        prepare(acct: auth(Storage) &Account) {
            let adminRoot = getAccount(adminAddr).storage.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
            acct.storage.save(<- adminRoot.createNewAdminRoot(), to: MFLAdmin.AdminRootStoragePath)
        }
        
        execute {
        }
    }
`;
