import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This tx gives a pack admin claim capability to an admin proxy.
  The admin proxy can now perform admin actions (for example mints packs).
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address, privatePath: Path) {

    let adminRootRef: &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &{MFLAdmin.AdminProxyPublic}
    let packAdminClaimCapability: Capability<&{MFLPack.PackAdminClaim}>

    prepare(acct: AuthAccount) {
        self.adminRootRef = acct.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
        let receiverAccount = getAccount(receiverAddress)
        self.receveiverAdminProxyRef = receiverAccount.getCapability<&{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath).borrow() ?? panic("Could not borrow AdminProxyPublic ref")
        let privateCapabilityPath = privatePath as? PrivatePath
        self.packAdminClaimCapability = acct.link<&{MFLPack.PackAdminClaim}>(privateCapabilityPath!, target: MFLPack.PackAdminStoragePath) ?? panic("path already exists")
    }

    execute {
        let name = self.packAdminClaimCapability.borrow()!.name
        self.adminRootRef.setAdminProxyClaimCapability(name: name, adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.packAdminClaimCapability)
    }
}
