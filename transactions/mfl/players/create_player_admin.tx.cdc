import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

transaction() {

    prepare(adminAcct: AuthAccount, futureAdminAcct: AuthAccount) {
        let playerAdminRef = adminAcct.borrow<&MFLPlayer.PlayerAdmin>(from: MFLPlayer.PlayerAdminStoragePath) ?? panic("Could not borrow player admin ref")
        let newPlayerAdmin <- playerAdminRef.createPlayerAdmin()
        futureAdminAcct.save(<- newPlayerAdmin, to: MFLPlayer.PlayerAdminStoragePath)
    }

    execute {
    }
}
