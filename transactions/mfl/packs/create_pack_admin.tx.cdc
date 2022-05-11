import MFLPack from 0x8ebcbfd516b1da27

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
