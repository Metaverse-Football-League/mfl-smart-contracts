import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This tx closes a specific drop.
**/

transaction(id: UInt64) {
    let dropAdminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.dropAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
    }

    execute {
        let dropAdminClaimCap = self.dropAdminProxyRef.getClaimCapability(name: "DropAdminClaim") ?? panic("DropAdminClaim capability not found")
        let dropAdminClaimRef = dropAdminClaimCap.borrow<&{MFLDrop.DropAdminClaim}>() ?? panic("Could not borrow DropAdminClaim")
        dropAdminClaimRef.setStatus(id: id, status: MFLDrop.Status.closed)
    }

}
