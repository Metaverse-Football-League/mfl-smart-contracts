import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

transaction() {

    prepare(acct: AuthAccount) {
        if acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) == nil {
            acct.save(<-MFLAdmin.createAdminProxy(), to: MFLAdmin.AdminProxyStoragePath)
        }
        acct.unlink(MFLAdmin.AdminProxyPublicPath)
        acct.link<&{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath, target: MFLAdmin.AdminProxyStoragePath)
    }

    execute {
    }

}
