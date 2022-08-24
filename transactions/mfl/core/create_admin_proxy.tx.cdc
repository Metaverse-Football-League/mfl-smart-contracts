import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/** 
  This tx creates an admin proxy which will allow 
  to receive capabilities from an admin root to perform admin actions.
**/

transaction() {

    prepare(acct: AuthAccount) {
        if acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) == nil {
            acct.save(<-MFLAdmin.createAdminProxy(), to: MFLAdmin.AdminProxyStoragePath)
        }
        acct.unlink(MFLAdmin.AdminProxyPublicPath)
        acct.link<&MFLAdmin.AdminProxy{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath, target: MFLAdmin.AdminProxyStoragePath)
    }

    execute {
    }

}
