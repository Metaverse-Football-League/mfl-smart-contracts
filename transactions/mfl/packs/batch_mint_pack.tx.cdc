import NonFungibleToken from 0x1d7e57aa55817448
import MFLAdmin from 0x8ebcbfd516b1da27
import MFLPack from 0x8ebcbfd516b1da27
import MFLPackTemplate from 0x8ebcbfd516b1da27

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

    pre {
        MFLPackTemplate.getPackTemplate(id: packTemplateID) != nil: "PackTemplate does not exist"
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