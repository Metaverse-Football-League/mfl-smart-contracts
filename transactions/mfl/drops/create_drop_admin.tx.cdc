import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

transaction() {

    prepare(adminAcct: AuthAccount, futureAdminAcct: AuthAccount) {
        let dropAdminRef = adminAcct.borrow<&MFLDrop.DropAdmin>(from: MFLDrop.DropAdminStoragePath) ?? panic("Could not borrow drop admin ref")
        let newDropAdmin <- dropAdminRef.createDropAdmin()
        futureAdminAcct.save(<- newDropAdmin, to: MFLDrop.DropAdminStoragePath)
    }

    execute {
    }
}
