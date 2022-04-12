import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This multi-sig tx creates a pack admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: AuthAccount, futureAdminAcct: AuthAccount) {
        let packAdminRef = adminAcct.borrow<&MFLPack.PackAdmin>(from: MFLPack.PackAdminStoragePath) ?? panic("Could not borrow pack admin ref")
        let newPackAdmin <- packAdminRef.createPackAdmin()
        futureAdminAcct.save(<- newPackAdmin, to: MFLPack.PackAdminStoragePath)
    }

    execute {
    }
}
