import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This tx transforms a club licence into a club and
  set a name and a description.
**/

transaction(clubID: UInt64, name: String, description: String) {
    let clubCollectionRef: auth(MFLClub.ClubAction) &MFLClub.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.clubCollectionRef = acct.storage.borrow<auth(MFLClub.ClubAction) &MFLClub.Collection>(from: MFLClub.CollectionStoragePath) ?? panic("Impossible to borrow the reference to the collection")
    }

    execute {
        self.clubCollectionRef.foundClub(id: clubID, name: name, description: description)
    }
}
