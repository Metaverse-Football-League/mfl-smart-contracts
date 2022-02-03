import MFLPackTemplate from "../packs/MFLPackTemplate.cdc"

pub contract MFLViews {

    // Events
    pub event ContractInitialized()

    pub struct PackDataViewV1 {
        pub let id: UInt64
        pub let packTemplateMintIndex: UInt32
        pub let packTemplate: MFLPackTemplate.PackTemplateData

        init(id: UInt64, packTemplateMintIndex: UInt32, packTemplate: MFLPackTemplate.PackTemplateData) {
            self.id = id
            self.packTemplateMintIndex = packTemplateMintIndex
            self.packTemplate = packTemplate
        }
    }

    pub struct PlayerMetadataViewV1 {
        pub let name: String?
        pub let nationalities: [String]?
        pub let positions: [String]?
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
        pub let season: UInt32
        pub let folderCID: String
        pub let metadata: PlayerMetadataViewV1

        init(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, folderCID: String) {
            self.id = id
            self.metadata = PlayerMetadataViewV1(metadata: metadata)
            self.season = season
            self.folderCID = folderCID
        }
    }

    init() {
        emit ContractInitialized()
    }

}
