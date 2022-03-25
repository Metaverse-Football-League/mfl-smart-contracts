import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This tx mints one pack. 
**/

transaction(packTemplateID: UInt64,  receiverAddr: Address){
    
    let packAdminProxyRef: &MFLAdmin.AdminProxy
    let receiverCollectionRef: &MFLPack.Collection{NonFungibleToken.CollectionPublic} 

    prepare(acct: AuthAccount) {
        self.packAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        self.receiverCollectionRef = getAccount(receiverAddr).getCapability<&MFLPack.Collection{NonFungibleToken.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow() ?? panic("Could not borrow receiver collection ref")
    }

    pre {
        MFLPackTemplate.getPackTemplate(id: packTemplateID) != nil: "PackTemplate does not exist"
    }

    execute {
        let packAdminClaimCap = self.packAdminProxyRef.getClaimCapability(name: "PackAdminClaim") ?? panic("PackAdminClaim capability not found")
        let packAdminClaimRef = packAdminClaimCap.borrow<&{MFLPack.PackAdminClaim}>() ?? panic("Could not borrow PackAdminClaim")
        let pack <- packAdminClaimRef.mintPack(packTemplateID: packTemplateID)
        self.receiverCollectionRef.deposit(token: <- pack)
    } 
}