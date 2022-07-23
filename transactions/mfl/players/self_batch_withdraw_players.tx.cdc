import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/** 
  This tx batch withdraws players NFTs and deposits them
  in the same collection (Fix to solve the problem of players who do not appear in the dapper wallet inventory).
**/

transaction(ids: [UInt64]) {

    let acctPlayerCollection: &MFLPlayer.Collection

    prepare(acct: AuthAccount) {
        self.acctPlayerCollection = acct.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) ?? panic("Could not borrow sender collection reference")
    }

    execute {
        let tokens <- self.acctPlayerCollection.batchWithdraw(ids: ids)

        let ids = tokens.getIDs()

        for id in ids {
            self.acctPlayerCollection.deposit(token: <-tokens.withdraw(withdrawID: id))
        }
        destroy tokens
    }
}