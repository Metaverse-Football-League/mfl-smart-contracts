import MFLPack from "../../../contracts/packs/MFLPack.cdc"

transaction() {

    prepare(acct: AuthAccount) {
        acct.save(<- MFLPack.createEmptyCollection(), to: MFLPack.CollectionStoragePath)
        acct.link<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath, target: MFLPack.CollectionStoragePath)
    }

    execute {
    }
}
