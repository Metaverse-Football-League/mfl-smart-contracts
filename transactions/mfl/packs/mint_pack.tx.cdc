import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This tx mints one pack. 
**/

transaction(packTemplateID: UInt64,  receiverAddr: Address){
    
    let packTemplateAdminProxyRef: &MFLAdmin.AdminProxy
    let receiverCollectionRef: &MFLPack.Collection{NonFungibleToken.CollectionPublic} 

    prepare(acct: AuthAccount) {
        self.packTemplateAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        self.receiverCollectionRef = getAccount(receiverAddr).getCapability<&MFLPack.Collection{NonFungibleToken.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow() ?? panic("Could not borrow receiver collection ref")
    }

    execute {
        let packAdminClaimCap = self.packTemplateAdminProxyRef.getClaimCapability(name: "PackAdminClaim") ?? panic("PackAdminClaim capability not found")
        let packAdminClaimRef = packAdminClaimCap.borrow<&{MFLPack.PackAdminClaim}>() ?? panic("Could not borrow PackAdminClaim")
        let pack <- packAdminClaimRef.mintPack(packTemplateID: packTemplateID)
        self.receiverCollectionRef.deposit(token: <- pack)
    } 
}