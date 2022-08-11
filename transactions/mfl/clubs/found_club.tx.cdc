import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

transaction(id: UInt64, name: String, description: String) {
    let clubCollectionRef: &MFLClub.Collection

    prepare(acct: AuthAccount) {
        self.clubCollectionRef = acct.borrow<&MFLClub.Collection>(from: MFLClub.CollectionStoragePath) ?? panic("Could not borrow club collection reference")
    }

    execute {
        self.clubCollectionRef.foundClub(id: id, name: name, description: description)
    }
}