export const WITHDRAW_PACK_FROM_GIVEN_ADDRESS = `import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/**
  This tx withdraws a pack NFT and deposits it
  in another collection.
**/

transaction(senderAddr: Address, receiverAddr: Address, id: UInt64) {

    let receiverRef: &MFLPack.Collection
    let senderRef: auth(NonFungibleToken.Withdraw) &MFLPack.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.receiverRef = getAccount(receiverAddr).capabilities.borrow<&MFLPack.Collection>(MFLPack.CollectionPublicPath) ??  panic("Could not borrow receiver collection reference")
        self.senderRef = getAccount(senderAddr).capabilities.borrow<auth(NonFungibleToken.Withdraw) &MFLPack.Collection>(
           MFLPack.CollectionPublicPath
       ) ?? panic("Could not borrow the collection reference")
    }

    execute {
        let nft <- self.senderRef.withdraw(withdrawID: id)
        self.receiverRef.deposit(token: <- nft)
    }
}`
