import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This tx creates a new pack template resource (based on a name, a description, 
  the maximum supply of packs of this type and an image url).
**/

transaction(
    name: String,
    description: String,
    maxSupply: UInt32,
    imageUrl: String,
    type: String,
    slotsNbr: UInt32,
    slotsType: [String],
    slotsChances: [{String: String}],
    slotsCount: [UInt32]
) {
    
    let packTemplateAdminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.packTemplateAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")       
    }

    pre {
        slotsNbr == UInt32(slotsType.length) : "Wrong number of parameters for slotsType"
        slotsNbr == UInt32(slotsChances.length) : "Wrong number of parameters for slotsChances"
        slotsNbr == UInt32(slotsCount.length) : "Wrong number of parameters for slotsCount"
    }

    execute {
        let packTemplateAdminClaimCap = self.packTemplateAdminProxyRef.getClaimCapability(name: "PackTemplateAdminClaim") ?? panic("PackTemplateAdminClaim capability not found")
        let packTemplateAdminClaimRef = packTemplateAdminClaimCap.borrow<&{MFLPackTemplate.PackTemplateAdminClaim}>() ?? panic("Could not borrow PackTemplateAdminClaim")
        let _slots = [] as [MFLPackTemplate.Slot]
        var i = 0 as UInt32
        while i < slotsNbr {
            _slots.append(MFLPackTemplate.Slot(type: slotsType[i], chances: slotsChances[i], count: slotsCount[i]))
            i = i + 1
        }
        packTemplateAdminClaimRef.createPackTemplate(name: name, description: description, maxSupply: maxSupply, imageUrl: imageUrl, type: type, slots: _slots)
    } 
}