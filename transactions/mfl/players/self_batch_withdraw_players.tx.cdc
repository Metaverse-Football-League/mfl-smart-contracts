import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx batch withdraws players NFTs and deposits them
  in the same collection (Fix to solve the problem of players who do not appear in the dapper wallet inventory).
**/

transaction(ids: [UInt64]) {

    let acctPlayerCollection: auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.acctPlayerCollection = acct.storage.borrow<auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) ?? panic("Could not borrow collection reference")
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
