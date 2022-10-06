import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"

/** 
  This multi-sig tx creates a squad admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: AuthAccount, futureAdminAcct: AuthAccount) {
        let squadAdminRef = adminAcct.borrow<&MFLClub.SquadAdmin>(from: MFLClub.SquadAdminStoragePath) ?? panic("Could not borrow squad admin ref")
        let newSquadAdmin <- squadAdminRef.createSquadAdmin()
        futureAdminAcct.save(<- newSquadAdmin, to: MFLClub.SquadAdminStoragePath)
    }

    execute {
    }
}
