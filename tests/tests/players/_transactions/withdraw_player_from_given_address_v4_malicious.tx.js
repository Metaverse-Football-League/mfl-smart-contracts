export const WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V4 = `import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx withdraws a player NFT and deposits it
  in another collection.
**/

transaction(senderAddr: Address, receiverAddr: Address, id: UInt64) {

    let receiverRef: auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection
    let senderRef: auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        let nftProviderCapStoragePath: StoragePath = /storage/MFLPlayerCollectionCap
        
        let cap = getAccount(receiverAddr).storage.copy<Capability<auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection>>(from: nftProviderCapStoragePath) ?? panic("Could not get capability")
        self.receiverRef = cap.borrow() ?? panic("Could not borrow the receiver reference")
        self.senderRef = acct.storage.borrow<auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection>(
           from: MFLPlayer.CollectionStoragePath
       ) ?? panic("Could not borrow the collection reference")
    }

    execute {
        let nft <- self.senderRef.withdraw(withdrawID: id)
        self.receiverRef.deposit(token: <- nft)
    }
}`
