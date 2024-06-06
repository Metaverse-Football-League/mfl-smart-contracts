import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This multi-sig tx creates a player admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: auth(BorrowValue) &Account, futureAdminAcct: auth(SaveValue) &Account) {
        let playerAdminRef = adminAcct.storage.borrow<auth(MFLPlayer.PlayerAdminAction) &MFLPlayer.PlayerAdmin>(from: MFLPlayer.PlayerAdminStoragePath) ?? panic("Could not borrow player admin ref")
        let newPlayerAdmin <- playerAdminRef.createPlayerAdmin()
        futureAdminAcct.storage.save(<- newPlayerAdmin, to: MFLPlayer.PlayerAdminStoragePath)
    }

    execute {
    }
}
