import MFLAdmin from 0x8ebcbfd516b1da27

/** 
  This multi-sig tx creates an admin root resource and save it in the new admin storage.
  This new admin root can then set capabilities to an admin proxy (to give admin rights),
  revoke specific capabilities or create a new admin root.
**/

transaction() {

    prepare(acct: AuthAccount, newAdmin: AuthAccount) {
        let adminRoot = acct.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
        newAdmin.save(<- adminRoot.createNewAdminRoot(), to: MFLAdmin.AdminRootStoragePath)
    }

    execute {
    }
}
