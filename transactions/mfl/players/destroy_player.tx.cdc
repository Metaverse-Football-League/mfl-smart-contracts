import NonFungibleToken from 0x1d7e57aa55817448
import MFLPlayer from 0x8ebcbfd516b1da27

/** 
  This tx destroys a specific player NFT.
**/

transaction(playerID: UInt64) {

    let playerNFT: @NonFungibleToken.NFT

    prepare(acct: AuthAccount) {
        let collection = acct.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath)
        self.playerNFT <- collection!.withdraw(withdrawID: playerID)
    }

    execute {
        destroy self.playerNFT
    }
}
