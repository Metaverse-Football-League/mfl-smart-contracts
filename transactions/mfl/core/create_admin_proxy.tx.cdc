import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/**
  This tx creates an admin proxy which will allow
  to receive capabilities from an admin root to perform admin actions.
**/

transaction() {

    prepare(acct: auth(BorrowValue, SaveValue, PublishCapability, UnpublishCapability, IssueStorageCapabilityController) &Account) {
        if acct.storage.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) != nil {
            return
        }

        acct.storage.save(<-MFLAdmin.createAdminProxy(), to: MFLAdmin.AdminProxyStoragePath)

        acct.capabilities.unpublish(MFLAdmin.AdminProxyPublicPath)
        let adminProxyCap = acct.capabilities.storage.issue<&MFLAdmin.AdminProxy>(MFLAdmin.AdminProxyStoragePath)
        acct.capabilities.publish(adminProxyCap, at: MFLAdmin.AdminProxyPublicPath)
    }

    execute {
    }

}
