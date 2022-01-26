import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This tx creates a standard pack NFT collection
  and exposes a public capability to interact with. 
**/

transaction() {

    prepare(acct: AuthAccount) {
        acct.save(<- MFLPack.createEmptyCollection(), to: MFLPack.CollectionStoragePath)
        acct.link<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath, target: MFLPack.CollectionStoragePath)
    }

    execute {
    }
}
