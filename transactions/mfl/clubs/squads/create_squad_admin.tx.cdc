import MFLClub from "../../../contracts/squads/MFLClub.cdc"

/**
  This multi-sig tx creates a squad admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: auth(BorrowValue) &Account, futureAdminAcct: auth(SaveValue) &Account) {
        let squadAdminRef = adminAcct.storage.borrow<auth(MFLClub.SquadAdminAction) &MFLClub.SquadAdmin>(from: MFLClub.SquadAdminStoragePath) ?? panic("Could not borrow squad admin ref")
        let newSquadAdmin <- squadAdminRef.createSquadAdmin()
        futureAdminAcct.storage.save(<- newSquadAdmin, to: MFLClub.SquadAdminStoragePath)
    }

    execute {
    }
}
