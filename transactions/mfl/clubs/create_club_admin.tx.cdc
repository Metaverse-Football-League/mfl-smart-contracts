import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This multi-sig tx creates a club admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: auth(BorrowValue) &Account, futureAdminAcct: auth(SaveValue) &Account) {
        let clubAdminRef = adminAcct.storage.borrow<auth(MFLClub.ClubAdminAction) &MFLClub.ClubAdmin>(from: MFLClub.ClubAdminStoragePath) ?? panic("Could not borrow club admin ref")
        let newClubAdmin <- clubAdminRef.createClubAdmin()
        futureAdminAcct.storage.save(<- newClubAdmin, to: MFLClub.ClubAdminStoragePath)
    }

    execute {
    }
}
