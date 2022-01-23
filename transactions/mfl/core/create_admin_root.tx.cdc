import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

transaction() {

    prepare(acct: AuthAccount, newAdmin: AuthAccount) {
        let adminRoot = acct.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
        newAdmin.save(<- adminRoot.createNewAdminRoot(), to: MFLAdmin.AdminRootStoragePath)
    }

    execute {
    }
}
