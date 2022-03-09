import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

/**
  This tx opens a pack, this will burn it and emit an event catched by the MFL backend to distribute the pack content.
  This will also create a player Collection (if the account doesn't have one).
 **/

// transaction(packID: UInt64) {

//     let collection: &MFLPack.Collection

//     prepare(acct: AuthAccount) {
//         self.collection = acct.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath) ?? panic("Could not borrow pack Collection ref")
        
//         fun hasPlayerCollection(): Bool {
//             return acct
//                 .getCapability<&MFLPlayer.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLPlayer.CollectionPublicPath)
//                 .check()
//         }

//         if !hasPlayerCollection() {
//             if acct.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) == nil {
//                 acct.save(<- MFLPlayer.createEmptyCollection(), to: MFLPlayer.CollectionStoragePath)
//             }
//             acct.unlink(MFLPlayer.CollectionPublicPath)
//             acct.link<&MFLPlayer.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLPlayer.CollectionPublicPath, target: MFLPlayer.CollectionStoragePath)
//         }
//     }

//     execute{
//         self.collection.openPack(id: packID)
//     }
// }

// This transcation opens an on-chain pack, revealing its contents and placing them into the account's NFT collection.
transaction(revealID: UInt64) {
    prepare(owner: AuthAccount) {
        let collectionRef = owner.borrow<&MFLPack.Collection>(from: MFLPack.CollectionStoragePath)!
        collectionRef.openPack(id: revealID)
    }
}