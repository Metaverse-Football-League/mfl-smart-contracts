import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPack from "../../../contracts/packs/MFLPack.cdc"

/** 
  This tx creates a standard pack NFT collection
  and exposes a public capability to interact with. 
**/

transaction() {

    prepare(acct: AuthAccount) {
        acct.save(<- MFLPack.createEmptyCollection(), to: MFLPack.CollectionStoragePath)
        acct.link<&MFLPack.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLPack.CollectionPublicPath, target: MFLPack.CollectionStoragePath)
    }

    execute {
    }
}
