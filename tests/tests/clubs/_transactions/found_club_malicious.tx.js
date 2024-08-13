export const FOUND_CLUB_MALICIOUS = `import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This tx transforms a club licence into a club and
  set a name and a description.
**/

transaction(ownerAddr: Address, clubID: UInt64, name: String, description: String) {
    let clubCollectionRef: &MFLClub.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.clubCollectionRef = getAccount(ownerAddr).capabilities.borrow<&MFLClub.Collection>(
           MFLClub.CollectionPublicPath
       ) ?? panic("Could not borrow the collection reference")
    }

    execute {
        self.clubCollectionRef.foundClub(id: clubID, name: name, description: description)
    }
}`;
