import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This multi-sig tx creates a drop admin resource and
  saves it in the new admin storage.
**/

transaction() {

    prepare(adminAcct: AuthAccount, futureAdminAcct: AuthAccount) {
        let dropAdminRef = adminAcct.borrow<&MFLDrop.DropAdmin>(from: MFLDrop.DropAdminStoragePath) ?? panic("Could not borrow drop admin ref")
        let newDropAdmin <- dropAdminRef.createDropAdmin()
        futureAdminAcct.save(<- newDropAdmin, to: MFLDrop.DropAdminStoragePath)
    }

    execute {
    }
}
