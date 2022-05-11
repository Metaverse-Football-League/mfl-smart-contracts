import MetadataViews from 0x1d7e57aa55817448
import MFLViews from 0x8ebcbfd516b1da27
import MFLPlayer from 0x8ebcbfd516b1da27

/** 
  This script returns a data representation of a player
  given a collection address, a player id and following the PlayerDataViewV1 view.
**/

pub fun main(address: Address, id: UInt64): MFLViews.PlayerDataViewV1 {

    let collection = getAccount(address)
        .getCapability(MFLPlayer.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowViewResolver(id: id)

    let view = nft.resolveView(Type<MFLViews.PlayerDataViewV1>())!

    let playerData = view as! MFLViews.PlayerDataViewV1
    
    return playerData
}