import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This tx allows packs to be opened for a specific pack template id. 
**/

transaction(id: UInt64){
    
    let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

    prepare(acct: auth(BorrowValue) &Account) {
        self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")       
    }

    execute {
        let packTemplateAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "PackTemplateAdminClaim") ?? panic("PackTemplateAdminClaim capability not found")
        let packTemplateAdminClaimRef = packTemplateAdminClaimCap.borrow<auth(MFLPackTemplate.PackTemplateAdminAction) &MFLPackTemplate.PackTemplateAdmin>() ?? panic("Could not borrow PackTemplateAdminClaim")
        packTemplateAdminClaimRef.allowToOpenPacks(id: id)
    } 
}