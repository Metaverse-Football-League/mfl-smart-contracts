import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This tx creates a standard player NFT collection
  and exposes a public capability to interact with. 
**/

transaction() {

    prepare(acct: AuthAccount) {
        acct.save(<- MFLPlayer.createEmptyCollection(), to: MFLPlayer.CollectionStoragePath)
        acct.link<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath, target: MFLPlayer.CollectionStoragePath)
    }

    execute {
    }
}
