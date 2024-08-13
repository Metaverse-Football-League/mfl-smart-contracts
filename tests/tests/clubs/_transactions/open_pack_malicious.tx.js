export const OPEN_PACK_MALICIOUS = `import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This tx opens a pack, this will burn it and emit an event catched by the MFL backend to distribute the pack content.
  This will also create a player Collection and a club Collection.
 **/
 
 transaction(walletAddr: Address, revealID: UInt64) {
    let collectionRef: auth(MFLPack.PackAction) &MFLPack.Collection

    prepare(owner: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability, UnpublishCapability) &Account) {
        self.collectionRef = getAccount(walletAddr).capabilities.borrow<auth(MFLPack.PackAction) &MFLPack.Collection>(MFLPack.CollectionPublicPath) ?? panic("Could not borrow the collection reference")
    }

    execute {
        self.collectionRef.openPack(id: revealID)
    }
}`
