import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import FUSD from "../../../contracts/_libs/FUSD.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

transaction(id: UInt64) {
    let dropAdminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.dropAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")       
    }

    execute {
        let dropAdminClaimCap = self.dropAdminProxyRef.getClaimCapability(name: "DropAdminClaim") ?? panic("DropAdminClaim capability not found")
        let dropAdminClaimRef = dropAdminClaimCap.borrow<&{MFLDrop.DropAdminClaim}>() ?? panic("Could not borrow DropAdminClaim")
        dropAdminClaimRef.setStatus(id: id, status: MFLDrop.Status.opened_all)
    }
    
}
 