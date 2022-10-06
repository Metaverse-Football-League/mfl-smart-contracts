import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This tx destroys a specific club NFT.
**/

transaction(clubID: UInt64) {

    let clubNFT: @NonFungibleToken.NFT

    prepare(acct: AuthAccount) {
        let collection = acct.borrow<&MFLClub.Collection>(from: MFLClub.CollectionStoragePath)
        self.clubNFT <- collection!.withdraw(withdrawID: clubID)
    }

    execute {
        destroy self.clubNFT
    }
}
 