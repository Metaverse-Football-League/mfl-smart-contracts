import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

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
 