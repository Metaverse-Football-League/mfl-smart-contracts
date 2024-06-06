import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This tx requests the update of the name and description
  given a club id. An on-chain event will be emitted
  and will be processed by the MFL backend.
**/


transaction(clubID: UInt64, name: String, description: String) {
    let clubCollectionRef: auth(MFLClub.ClubAction) &MFLClub.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.clubCollectionRef = acct.storage.borrow<auth(MFLClub.ClubAction) &MFLClub.Collection>(from: MFLClub.CollectionStoragePath) ?? panic("Impossible to borrow the reference to the collection")
    }


    execute {
        let info: {String: String} = {}
        info.insert(key: "name", name)
        info.insert(key: "description", description)
        self.clubCollectionRef.requestClubInfoUpdate(id: clubID, info: info)
    }
}
