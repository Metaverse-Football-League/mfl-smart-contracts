import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/**
  This multi-sig tx creates a pack admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: auth(BorrowValue) &Account, futureAdminAcct: auth(SaveValue) &Account) {
        let packAdminRef = adminAcct.storage.borrow<auth(MFLPack.PackAdminAction) &MFLPack.PackAdmin>(from: MFLPack.PackAdminStoragePath) ?? panic("Could not borrow pack admin ref")
        let newPackAdmin <- packAdminRef.createPackAdmin()
        futureAdminAcct.storage.save(<- newPackAdmin, to: MFLPack.PackAdminStoragePath)
    }

    execute {
    }
}
