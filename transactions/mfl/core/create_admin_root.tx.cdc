import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/**
  This multi-sig tx creates an admin root resource and save it in the new admin storage.
  This new admin root can then set capabilities to an admin proxy (to give admin rights),
  revoke specific capabilities or create a new admin root.
**/

transaction() {

    prepare(acct: auth(BorrowValue) &Account, newAdmin: auth(SaveValue) &Account) {
        let adminRoot = acct.storage.borrow<auth(MFLAdmin.AdminRootAction) &MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
        newAdmin.storage.save(<- adminRoot.createNewAdminRoot(), to: MFLAdmin.AdminRootStoragePath)
    }

    execute {
    }
}
