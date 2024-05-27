import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/**
  This tx destroys a specific pack NFT.
**/

transaction(packID: UInt64) {

    let packNFT: @{NonFungibleToken.NFT}

    prepare(acct: auth(BorrowValue) &Account) {
        let collection = acct.storage.borrow<auth(NonFungibleToken.Withdraw) &MFLPack.Collection>(from: MFLPack.CollectionStoragePath)
        self.packNFT <- collection!.withdraw(withdrawID: packID)
    }

    execute {
        destroy self.packNFT
    }
}
