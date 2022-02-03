import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This tx creates a new drop resource (based on a pack price, a pack template id 
  and the maximum number of packs an account can have).
  The drop is closed by default, which means that no account will be able to buy packs.
  Each drop must be linked to a valid pack template id.
**/

transaction(
  name: String,
  price: UFix64,
  packTemplateID: UInt64,
  maxTokensPerAddress: UInt32
) {
    let dropAdminProxyRef: &MFLAdmin.AdminProxy

    prepare(acct: AuthAccount) {
        self.dropAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")       
    }

    execute {
        let dropAdminClaimCap = self.dropAdminProxyRef.getClaimCapability(name: "DropAdminClaim") ?? panic("DropAdminClaim capability not found")
        let dropAdminClaimRef = dropAdminClaimCap.borrow<&{MFLDrop.DropAdminClaim}>() ?? panic("Could not borrow DropAdminClaim")
        dropAdminClaimRef.createDrop(name: name, price: price, packTemplateID: packTemplateID, maxTokensPerAddress: maxTokensPerAddress)
    }
    
}