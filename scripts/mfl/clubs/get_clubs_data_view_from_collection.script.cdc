import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

/**
  This script returns a data representation array of clubs
  given a collection address, a list of clubs ids and following the ClubDataViewV1 view.
**/

access
fun main(address: Address, clubsIds: [UInt64]): [MFLViews.ClubDataViewV1] {

    let collection = getAccount(address).capabilities.borrow<&MFLClub.Collection>(
           MFLClub.CollectionPublicPath
        ) ?? panic("Could not borrow the collection reference")

    let clubsDatas: [MFLViews.ClubDataViewV1] = []

    for id in clubsIds {
        let nft = collection.borrowViewResolver(id: id)
        let view = nft.resolveView(Type<MFLViews.ClubDataViewV1>())!
        let clubData = view as! MFLViews.ClubDataViewV1
        clubsDatas.append(clubData)
    }

    return clubsDatas
}
