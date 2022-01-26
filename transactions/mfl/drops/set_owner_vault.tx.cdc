import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import FUSD from "../../../contracts/_libs/FUSD.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This tx set the owner vault capability of the MFLDrop contract.
  When someone buys a pack, the amount (usually FUSD) is sent to 
  the owner vault.
**/

transaction() {
    let dropAdminProxyRef: &MFLAdmin.AdminProxy
    let ownerVaultCap: Capability<&FUSD.Vault{FungibleToken.Receiver}>

    prepare(acct: AuthAccount) {
        self.dropAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")       
        self.ownerVaultCap = acct.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
    }

    execute {
        let dropAdminClaimCap = self.dropAdminProxyRef.getClaimCapability(name: "DropAdminClaim") ?? panic("DropAdminClaim capability not found")
        let dropAdminClaimRef = dropAdminClaimCap.borrow<&{MFLDrop.DropAdminClaim}>() ?? panic("Could not borrow DropAdminClaim")
        dropAdminClaimRef.setOwnerVault(vault: self.ownerVaultCap)
    }
    
}