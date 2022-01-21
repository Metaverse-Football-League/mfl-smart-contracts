import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

transaction() {

    prepare(acct: AuthAccount) {
        acct.save(<- MFLPlayer.createEmptyCollection(), to: MFLPlayer.CollectionStoragePath)
        acct.link<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath, target: MFLPlayer.CollectionStoragePath)
    }

    execute {
    }
}
