import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This tx mints an arbitray number of packs. 
**/

transaction(packTemplateID: UInt64,  receiverAddr: Address, nbToMint: UInt32){
    
    let packTemplateAdminProxyRef: &MFLAdmin.AdminProxy
    let receiverCollectionRef: &MFLPack.Collection{NonFungibleToken.CollectionPublic} 

    prepare(acct: AuthAccount) {
        self.packTemplateAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        self.receiverCollectionRef = getAccount(receiverAddr).getCapability<&MFLPack.Collection{NonFungibleToken.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow() ?? panic("Could not borrow receiver collection ref")
    }

    execute {
        let packAdminClaimCap = self.packTemplateAdminProxyRef.getClaimCapability(name: "PackAdminClaim") ?? panic("PackAdminClaim capability not found")
        let packAdminClaimRef = packAdminClaimCap.borrow<&{MFLPack.PackAdminClaim}>() ?? panic("Could not borrow PackAdminClaim")
        let packs <- packAdminClaimRef.batchMintPack(packTemplateID: packTemplateID, nbToMint: nbToMint)
        let ids = packs.getIDs()
        for id in ids {
            self.receiverCollectionRef.deposit(token: <-packs.withdraw(withdrawID: id))
        }
        destroy packs
    } 
}