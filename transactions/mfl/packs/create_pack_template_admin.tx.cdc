import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This multi-sig tx creates a pack template admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: auth(BorrowValue) &Account, futureAdminAcct: auth(SaveValue) &Account) {
        let packTemplateAdminRef = adminAcct.storage.borrow<auth(MFLPackTemplate.PackTemplateAdminAction) &MFLPackTemplate.PackTemplateAdmin>(from: MFLPackTemplate.PackTemplateAdminStoragePath) ?? panic("Could not borrow packTemplate admin ref")
        let newPackTemplateAdmin <- packTemplateAdminRef.createPackTemplateAdmin()
        futureAdminAcct.storage.save(<- newPackTemplateAdmin, to: MFLPackTemplate.PackTemplateAdminStoragePath)
    }

    execute {
    }
}
