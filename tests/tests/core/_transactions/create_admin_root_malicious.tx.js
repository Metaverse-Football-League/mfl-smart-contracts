export const CREATE_ADMIN_ROOT_MALICIOUS = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

    transaction() {
        prepare(acct: auth(Storage) &Account) {
            let adminRoot <- create AdminRoot()
            acct.storage.save(<-adminRoot, to: MFLAdmin.AdminRootStoragePath)
        }
        
        execute {
        }
    }
`;
