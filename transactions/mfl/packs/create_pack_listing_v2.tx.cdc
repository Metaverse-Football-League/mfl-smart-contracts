import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This tx mints an arbitray number of packs. 
**/

transaction(packTemplateID: UInt64,  receiverAddr: Address, nbToMint: UInt32){
    
    let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy
    let receiverCollectionRef: &MFLPack.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")       
        self.receiverCollectionRef = getAccount(receiverAddr).capabilities.borrow<&MFLPack.Collection>(
                MFLPack.CollectionPublicPath
            ) ?? panic("Could not get receiver reference to the NFT Collection")
    }

    execute {
        let packAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "PackAdminClaim") ?? panic("PackAdminClaim capability not found")
        let packAdminClaimRef = packAdminClaimCap.borrow<auth(MFLPack.PackAdminAction) &MFLPack.PackAdmin>() ?? panic("Could not borrow PackAdmin")
        let packs <- packAdminClaimRef.batchMintPack(packTemplateID: packTemplateID, nbToMint: nbToMint)
        let ids = packs.getIDs()
        for id in ids {
            self.receiverCollectionRef.deposit(token: <-packs.withdraw(withdrawID: id))
        }
        destroy packs
    } 
}