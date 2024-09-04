export const BATCH_WITHDRAW_CLUB_FROM_GIVEN_ADDRESS = `import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This tx withdraws a club NFT and deposits it
  in another collection.
**/

transaction(senderAddr: Address, receiverAddr: Address, ids: [UInt64]) {

    let receiverRef: &MFLClub.Collection
    let senderRef: auth(NonFungibleToken.Withdraw) &MFLClub.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.receiverRef = getAccount(receiverAddr).capabilities.borrow<&MFLClub.Collection>(MFLClub.CollectionPublicPath) ??  panic("Could not borrow receiver collection reference")
        self.senderRef = getAccount(senderAddr).capabilities.borrow<auth(NonFungibleToken.Withdraw) &MFLClub.Collection>(
           MFLClub.CollectionPublicPath
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
