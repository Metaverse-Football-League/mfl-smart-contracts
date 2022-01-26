import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This tx creates a new pack template resource (based on a name, a description, 
  the maximum supply of packs of this type and an image url).
**/

transaction(name: String, description: String, maxSupply: UInt32, imageUrl: String){
    
    let packTemplateAdminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.packTemplateAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")       
    }

    execute {
        let packTemplateAdminClaimCap = self.packTemplateAdminProxyRef.getClaimCapability(name: "PackTemplateAdminClaim") ?? panic("PackTemplateAdminClaim capability not found")
        let packTemplateAdminClaimRef = packTemplateAdminClaimCap.borrow<&{MFLPackTemplate.PackTemplateAdminClaim}>() ?? panic("Could not borrow PackTemplateAdminClaim")
        packTemplateAdminClaimRef.createPackTemplate(name: name, description: description, maxSupply: maxSupply, imageUrl: imageUrl)
    } 
}