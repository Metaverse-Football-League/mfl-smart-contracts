import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/** 
  This tx removes an admin proxy.
**/

transaction() {

    prepare(acct: AuthAccount) {
        acct.unlink(MFLAdmin.AdminProxyPublicPath)
        if acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) != nil {
            let adminProxyStorage <- acct.load<@MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath)
            destroy adminProxyStorage
        }
    }

    execute {
    }

}
