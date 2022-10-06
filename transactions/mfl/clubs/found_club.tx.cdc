import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This tx transforms a club licence into a club and
  set a name and a description.
**/

transaction(clubID: UInt64, name: String, description: String) {
    let clubCollectionRef: &MFLClub.Collection

    prepare(acct: AuthAccount) {
        self.clubCollectionRef = acct.borrow<&MFLClub.Collection>(from: MFLClub.CollectionStoragePath) ?? panic("Could not borrow club collection reference")
    }

    execute {
        self.clubCollectionRef.foundClub(id: clubID, name: name, description: description)
    }
}