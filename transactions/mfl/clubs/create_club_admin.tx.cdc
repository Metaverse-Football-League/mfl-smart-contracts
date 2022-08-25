import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This multi-sig tx creates a club admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: AuthAccount, futureAdminAcct: AuthAccount) {
        let clubAdminRef = adminAcct.borrow<&MFLClub.ClubAdmin>(from: MFLClub.ClubAdminStoragePath) ?? panic("Could not borrow club admin ref")
        let newClubAdmin <- clubAdminRef.createClubAdmin()
        futureAdminAcct.save(<- newClubAdmin, to: MFLClub.ClubAdminStoragePath)
    }

    execute {
    }
}
