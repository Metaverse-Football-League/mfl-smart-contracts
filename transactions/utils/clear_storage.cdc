import FUSD from "../../contracts/lib/FUSD.cdc"
import MFLPlayer from "../../contracts/MFLPlayer.cdc"
import MFLPackTemplate from "../../contracts/MFLPackTemplate.cdc"
import MFLPack from "../../contracts/MFLPack.cdc"
import MFLAdmin from "../../contracts/MFLAdmin.cdc"
// import MFLRaffleV1 from "../../contracts/MFLRaffleV1.cdc"

transaction {

  prepare(acct: AuthAccount) {


    let fusd <- acct.load<@FUSD.Vault>(from: /storage/fusdVault)
    let collectionPlayer <- acct.load<@MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath)
    let adminRoot <- acct.load<@MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath)
    let claims <- acct.load<@MFLAdmin.Claims>(from: MFLAdmin.ClaimsStoragePath)
    let adminProxy <- acct.load<@MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath)
    // let collectionPackTemplate <- acct.load<@MFLPackTemplate.Collection>(from: MFLPackTemplate.CollectionStoragePath)
    let collectionPack <- acct.load<@MFLPack.Collection>(from: MFLPack.CollectionStoragePath)

    // let adminResourcePlayer <- acct.load<@MFLPlayer.Admin>(from: MFLPlayer.AdminStoragePath)
    // let adminResourceRaffle <- acct.load<@MFLRaffleV1.Admin>(from: MFLRaffleV1.AdminStoragePath)

    destroy fusd
    destroy collectionPlayer
    destroy adminRoot
    destroy claims
    destroy adminProxy
    // destroy collectionPackTemplate
    destroy collectionPack

    // destroy adminResourcePlayer
    // destroy adminResourceRaffle
  }

  execute {}

}
