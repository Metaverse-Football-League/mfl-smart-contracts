import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/** 
  This script returns a data representation of a club
  given a collection address, a club id and following the ClubDataViewV1 view.
**/

pub fun main(address: Address, id: UInt64): MFLViews.ClubDataViewV1 {

    let collection = getAccount(address)
        .getCapability(MFLClub.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to MFLClub collection")

    let nft = collection.borrowViewResolver(id: id)

    let view = nft.resolveView(Type<MFLViews.ClubDataViewV1>())!

    let clubData = view as! MFLViews.ClubDataViewV1
    
    return clubData
}