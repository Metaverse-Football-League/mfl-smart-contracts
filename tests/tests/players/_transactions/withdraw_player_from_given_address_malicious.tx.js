export const WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS = `import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx withdraws a player NFT and deposits it
  in another collection.
**/

transaction(senderAddr: Address, receiverAddr: Address, id: UInt64) {

    let receiverRef: &MFLPlayer.Collection
    let senderRef: auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.receiverRef = getAccount(receiverAddr).capabilities.borrow<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath) ??  panic("Could not borrow receiver collection reference")
        self.senderRef = getAccount(senderAddr).capabilities.borrow<auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection>(
           MFLPlayer.CollectionPublicPath
       ) ?? panic("Could not borrow the collection reference")
    }

    execute {
        let nft <- self.senderRef.withdraw(withdrawID: id)
        self.receiverRef.deposit(token: <- nft)
    }
}`
