import MFLAdmin from 0x8ebcbfd516b1da27
import MFLPackTemplate from 0x8ebcbfd516b1da27

/** 
  This tx allows packs to be opened for a specific pack template id. 
**/

transaction(id: UInt64){
    
    let packTemplateAdminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.packTemplateAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")       
    }

    execute {
        let packTemplateAdminClaimCap = self.packTemplateAdminProxyRef.getClaimCapability(name: "PackTemplateAdminClaim") ?? panic("PackTemplateAdminClaim capability not found")
        let packTemplateAdminClaimRef = packTemplateAdminClaimCap.borrow<&{MFLPackTemplate.PackTemplateAdminClaim}>() ?? panic("Could not borrow PackTemplateAdminClaim")
        packTemplateAdminClaimRef.allowToOpenPacks(id: id)
    } 
}