//TODO comments

pub contract MFLCompetition {
    
    // Events
    pub event ContractInitialized()
    pub event Minted(id: UInt64)
    pub event Destroyed(id: UInt64)

    // Named Paths
    pub let CompetitionAdminStoragePath: StoragePath

    access(self) let competitions: @{UInt64: Competition}
    access(self) let competitionsDatas: {UInt64: CompetitionData}

    // The total number of Competitions that have been minted
    pub var totalSupply: UInt64

    pub struct CompetitionData {
        pub let id: UInt64
        pub let type: String
        pub let name: String
        access(contract) let metadata: {String: AnyStruct}

        init(id: UInt64, type: String, name: String, metadata: {String: AnyStruct}) {
            self.id = id
            self.type = type
            self.name = name
            self.metadata = metadata
        }
    }

    pub resource Competition {
        pub let id: UInt64

        init(id: UInt64) {
            self.id = id
            MFLCompetition.totalSupply = MFLCompetition.totalSupply + (1 as UInt64)
            emit Minted(id: self.id)
        }

        destroy() {
           // ? remove data in central ledger ?
           emit Destroyed(id: self.id)
        }
    }

    // This interface allows any account that has a private capability to a CompetitionAdminClaim to call the methods below
    pub resource interface CompetitionAdminClaim {
        pub let name: String
        pub fun mintCompetition(id: UInt64, type: String, name: String, metadata: {String: AnyStruct})
    }

    pub resource CompetitionAdmin: CompetitionAdminClaim {
        pub let name: String
    
        init() {
            self.name = "CompetitionAdminClaim"
        }

        pub fun mintCompetition(id: UInt64, type: String, name: String, metadata: {String: AnyStruct}) {
            let competition <- create Competition(id: id)
            MFLCompetition.competitionsDatas[id] = MFLCompetition.CompetitionData(
                id: id,
                type: type,
                name: name,
                metadata: metadata
            )
            let oldCompetition <- MFLCompetition.competitions[id] <- competition
            destroy oldCompetition
        }
    }

    init() {
        // Set our named paths
        self.CompetitionAdminStoragePath = /storage/MFLCompetitionAdmin

        // Create CompetitionAdmin resource and save it to storage
        self.account.save(<- create CompetitionAdmin() , to: self.CompetitionAdminStoragePath)

        // Initialize contract fields
        self.totalSupply = 0
        self.competitions <- {}
        self.competitionsDatas = {}
        
        emit ContractInitialized()
    }
}