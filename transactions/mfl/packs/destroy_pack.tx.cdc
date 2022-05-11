import NonFungibleToken from 0x1d7e57aa55817448
import MFLPack from 0x8ebcbfd516b1da27

/** 
  This tx destroys a specific pack NFT.
**/

transaction(packID: UInt64) {

    let packNFT: @NonFungibleToken.NFT

    prepare(acct: AuthAccount) {
        let collection = acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath)
        self.packNFT <- collection!.withdraw(withdrawID: packID)
    }

    execute {
        destroy self.packNFT
    }
}
