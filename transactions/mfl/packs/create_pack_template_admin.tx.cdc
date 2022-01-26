import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

/** 
  This multi-sig tx creates a pack template admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: AuthAccount, futureAdminAcct: AuthAccount) {
        let packTemplateAdminRef = adminAcct.borrow<&MFLPackTemplate.PackTemplateAdmin>(from: MFLPackTemplate.PackTemplateAdminStoragePath) ?? panic("Could not borrow packTemplate admin ref")
        let newPackTemplateAdmin <- packTemplateAdminRef.createPackTemplateAdmin()
        futureAdminAcct.save(<- newPackTemplateAdmin, to: MFLPackTemplate.PackTemplateAdminStoragePath)
    }

    execute {
    }
}
