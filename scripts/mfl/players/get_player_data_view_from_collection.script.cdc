import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
import MFLViews from "../../../contracts/views/MFLViews.cdc"

/** 
  This script returns a data representation of a player
  given a collection address and a player id and following the PlayerDataV1 View
**/

pub struct PlayerDataV1 {
    pub let id: UInt64
    pub let season: UInt32
    pub let ipfsURI: String
    pub let name: String
    pub let nationalities: [String]
    pub let positions: [String]
    pub let preferredFoot: String
    pub let ageAtMint: UInt32
    pub let height: UInt32
    pub let overall: UInt32
    pub let pace: UInt32
    pub let shooting: UInt32
    pub let passing: UInt32
    pub let dribbling: UInt32
    pub let defense: UInt32
    pub let physical: UInt32
    pub let goalkeeping: UInt32
    pub let potential: String
    pub let resistance: UInt32
    pub let owner: Address
    pub let type: String
    
    init(
        id: UInt64,
        season: UInt32,
        ipfsURI: String,
        name: String,
        nationalities: [String],
        positions: [String],
        preferredFoot: String,
        ageAtMint: UInt32,
        height: UInt32,
        overall: UInt32,
        pace: UInt32,
        shooting: UInt32,
        passing: UInt32,
        dribbling: UInt32,
        defense: UInt32,
        physical: UInt32,
        goalkeeping: UInt32,
        potential: String,
        resistance: UInt32,
        owner: Address,
        nftType: String,
    ) {
        self.id = id
        self.season = season
        self.ipfsURI = ipfsURI
        self.name = name
        self.nationalities = nationalities
        self.positions = positions
        self.preferredFoot = preferredFoot
        self.ageAtMint = ageAtMint
        self.height = height
        self.overall = overall
        self.pace = pace
        self.shooting = shooting
        self.passing = passing
        self.dribbling = dribbling
        self.defense = defense
        self.physical = physical
        self.goalkeeping = goalkeeping
        self.potential = potential
        self.resistance = resistance
        self.owner = owner
        self.type = nftType
    }
}


pub fun main(address: Address, id: UInt64): PlayerDataV1 {
    let account = getAccount(address)

    let collection = account
        .getCapability(MFLPlayer.CollectionPublicPath)
        .borrow<&{MFLPlayer.CollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowPlayer(id: id)!

    // Get the basic display information for this NFT
    let view = nft.resolveView(Type<MFLViews.PlayerDataViewV1>())!

    let playerData = view as! MFLViews.PlayerDataViewV1
    
    let owner: Address = nft.owner!.address
    let nftType = nft.getType()

    return PlayerDataV1(
        id: playerData.id,
        season: playerData.season,
        ipfsURI: playerData.ipfsURI,
        name: playerData.name,
        nationalities: playerData.nationalities,
        positions: playerData.positions,
        preferredFoot: playerData.preferredFoot,
        ageAtMint: playerData.ageAtMint,
        height: playerData.height,
        overall: playerData.overall,
        pace: playerData.pace,
        shooting: playerData.shooting,
        passing: playerData.passing,
        dribbling: playerData.dribbling,
        defense: playerData.defense,
        physical: playerData.physical,
        goalkeeping: playerData.goalkeeping,
        potential: playerData.potential,
        resistance: playerData.resistance,
        owner: owner,
        nftType: nftType.identifier
    )
}
