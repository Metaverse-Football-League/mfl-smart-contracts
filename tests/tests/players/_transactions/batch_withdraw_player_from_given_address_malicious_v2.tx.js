export const BATCH_WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V2 = `import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx withdraws a player NFT and deposits it
  in another collection.
**/

transaction(senderAddr: Address, receiverAddr: Address, ids: [UInt64]) {

    let receiverRef: &MFLPlayer.Collection
    let senderRef: &MFLPlayer.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.receiverRef = getAccount(receiverAddr).capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath) ??  panic("Could not borrow receiver collection reference")
        self.senderRef = getAccount(senderAddr).capabilities.borrow<&MFLPlayer.Collection>(
           MFLPlayer.CollectionPublicPath
       ) ?? panic("Could not borrow the collection reference")
    }

    execute {
        let tokens <- self.senderRef.batchWithdraw(ids: ids)
        
        let ids = tokens.getIDs()

        for id in ids {
            self.receiverRef.deposit(token: <-tokens.withdraw(withdrawID: id))
        }
        destroy tokens
    }
}`
