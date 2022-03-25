import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import NFTStorefront from "../../../contracts/_libs/NFTStorefront.cdc"

/** 
  This tx gives a NFTStorefront claim capability to an admin proxy.
  The admin proxy can now list or remove an item on behalf of the owner of the storefront.
  The path capability is private (which can be deleted at any time by the owner of the storage).
**/

transaction(receiverAddress: Address, privatePath: Path) {

    let adminRootRef: &MFLAdmin.AdminRoot
    let receveiverAdminProxyRef: &{MFLAdmin.AdminProxyPublic}
    let storefrontClaimCapability: Capability<&{NFTStorefront.StorefrontManager}>

    prepare(acct: AuthAccount) {
        self.adminRootRef = acct.borrow<&MFLAdmin.AdminRoot>(from: MFLAdmin.AdminRootStoragePath) ?? panic("Could not borrow AdminRoot ref")
        let receiverAccount = getAccount(receiverAddress)
        self.receveiverAdminProxyRef = receiverAccount.getCapability<&{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath).borrow() ?? panic("Could not borrow AdminProxyPublic ref")
        let privateCapabilityPath = privatePath as? PrivatePath
        self.storefrontClaimCapability = acct.link<&{NFTStorefront.StorefrontManager}>(privateCapabilityPath!, target: /storage/NFTStorefront) ?? panic("path already exists")
    }

    execute {
        self.adminRootRef.setAdminProxyClaimCapability(name: "NFTStorefrontClaim", adminProxyRef: self.receveiverAdminProxyRef, newCapability: self.storefrontClaimCapability)
    }
}
