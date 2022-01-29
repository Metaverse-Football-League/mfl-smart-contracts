pub contract MFLViews {

    // Events
    pub event ContractInitialized()

    pub struct PlayerDataViewV1 {
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

        //TODO maybe we can return nil if key does not exist ?
        init(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, ipfsURI: String) {
            self.id = id
            self.season = season
            self.ipfsURI = ipfsURI
            self.name = metadata["name"] as! String? ?? ""
            self.nationalities = metadata["nationalities"] as! [String]? ?? []
            self.positions = metadata["positions"] as! [String]? ?? []
            self.preferredFoot = metadata["preferredFoot"] as! String? ?? ""
            self.ageAtMint = metadata["ageAtMint"] as! UInt32? ?? 0 as UInt32
            self.height = metadata["height"] as! UInt32? ?? 0 as UInt32
            self.overall = metadata["overall"] as! UInt32? ?? 0 as UInt32
            self.pace = metadata["pace"] as! UInt32? ?? 0 as UInt32
            self.shooting = metadata["shooting"] as! UInt32? ?? 0 as UInt32
            self.passing = metadata["passing"] as! UInt32? ?? 0 as UInt32
            self.dribbling = metadata["dribbling"] as! UInt32? ?? 0 as UInt32
            self.defense = metadata["defense"] as! UInt32? ?? 0 as UInt32
            self.physical = metadata["physical"] as! UInt32? ?? 0 as UInt32
            self.goalkeeping = metadata["goalkeeping"] as! UInt32? ?? 0 as UInt32
            self.potential = metadata["potential"] as! String? ?? ""
            self.resistance = metadata["resistance"] as! UInt32? ?? 0 as UInt32
        }
    }

    init() {
        emit ContractInitialized()
    }

}
