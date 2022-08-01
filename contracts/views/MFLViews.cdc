import MetadataViews from "../_libs/MetadataViews.cdc"
import MFLPackTemplate from "../packs/MFLPackTemplate.cdc"
import MFLClub from "../clubs/MFLClub.cdc"

/**
  This contract defines MFL customised views. They are used to represent NFTs data.
  This allows us to take full advantage of the new metadata standard.
**/

pub contract MFLViews {

    // Events
    pub event ContractInitialized()

    pub struct PackDataViewV1 {
        pub let id: UInt64
        pub let packTemplate: MFLPackTemplate.PackTemplateData

        init(id: UInt64, packTemplate: MFLPackTemplate.PackTemplateData) {
            self.id = id
            self.packTemplate = packTemplate
        }
    }

    pub struct PlayerMetadataViewV1 {
        pub let name: String?
        access(contract) let nationalities: [String]?
        access(contract) let positions: [String]?
        pub let preferredFoot: String?
        pub let ageAtMint: UInt32?
        pub let height: UInt32?
        pub let overall: UInt32?
        pub let pace: UInt32?
        pub let shooting: UInt32?
        pub let passing: UInt32?
        pub let dribbling: UInt32?
        pub let defense: UInt32?
        pub let physical: UInt32?
        pub let goalkeeping: UInt32?
        pub let potential: String?
        pub let resistance: UInt32?

        init(metadata: {String: AnyStruct}) {
            self.name = metadata["name"] as! String?
            self.nationalities = metadata["nationalities"] as! [String]?
            self.positions = metadata["positions"] as! [String]?
            self.preferredFoot = metadata["preferredFoot"] as! String?
            self.ageAtMint = metadata["ageAtMint"] as! UInt32?
            self.height = metadata["height"] as! UInt32?
            self.overall = metadata["overall"] as! UInt32?
            self.pace = metadata["pace"] as! UInt32?
            self.shooting = metadata["shooting"] as! UInt32?
            self.passing = metadata["passing"] as! UInt32?
            self.dribbling = metadata["dribbling"] as! UInt32?
            self.defense = metadata["defense"] as! UInt32?
            self.physical = metadata["physical"] as! UInt32?
            self.goalkeeping = metadata["goalkeeping"] as! UInt32?
            self.potential = metadata["potential"] as! String?
            self.resistance = metadata["resistance"] as! UInt32?
        }
    } 

    pub struct PlayerDataViewV1 {
        pub let id: UInt64
        pub let metadata: PlayerMetadataViewV1
        pub let season: UInt32
        pub let thumbnail: {MetadataViews.File}

        init(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, thumbnail: {MetadataViews.File}) {
            self.id = id
            self.metadata = PlayerMetadataViewV1(metadata: metadata)
            self.season = season
            self.thumbnail = thumbnail
        }
    }

    pub struct ClubMetadataTeamsViewV1 {
        pub let teams: [MFLClub.Team]

        init(metadata: [{String: AnyStruct}]) {
            var teams = [] as [MFLClub.Team] 
            for team in metadata {
                teams.append(team as! MFLClub.Team)
            }
            self.teams = teams
        }
    }

    pub struct ClubMetadataMainViewV1 {
        pub let status: MFLClub.Status?
        pub let name: String?
        pub let description: String?
        pub let city: String?
        pub let country: String?

        init(
            metadata: {String: AnyStruct}
        ) {
            self.status = metadata["status"] as! MFLClub.Status?
            self.name = metadata["name"] as! String?
            self.description = metadata["description"] as! String?
            self.city = metadata["city"] as! String?
            self.country = metadata["country"] as! String?
        }
    }

    pub struct ClubDataViewV1 {
        pub let id: UInt64
        pub let metadataMain: ClubMetadataMainViewV1
        pub let metadataTeams: ClubMetadataTeamsViewV1

        init(id: UInt64, metadataMain: {String: AnyStruct}, metadataTeams: [{String: AnyStruct}]) {
            self.id = id
            self.metadataMain = ClubMetadataMainViewV1(metadata: metadataMain)
            self.metadataTeams = ClubMetadataTeamsViewV1(metadata: metadataTeams)
        }
    }

    init() {
        emit ContractInitialized()
    }
}
