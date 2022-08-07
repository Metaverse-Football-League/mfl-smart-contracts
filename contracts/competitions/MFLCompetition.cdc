//TODO comments

pub contract MFLCompetition {
    
    // Events
    pub event ContractInitialized()
    pub event Minted(id: UInt64)
    pub event Updated(id: UInt64)
    pub event Destroyed(id: UInt64)
    pub event CompetitionMembershipCreatedOrUpdated(competitionID: UInt64, squadID: UInt64)
    pub event CompetitionMembershipRemoved(competitionID: UInt64, squadID: UInt64)

    // Named Paths
    pub let CompetitionAdminStoragePath: StoragePath

    access(self) let competitions: @{UInt64: Competition}
    access(self) let competitionsDatas: {UInt64: CompetitionData}
    access(self) let competitionsMembershipsByCompetitionId: {UInt64: {UInt64: CompetitionMembership}}
    access(self) let competitionsMembershipsBySquadId: {UInt64: {UInt64: CompetitionMembership}}

    // The total number of Competitions that have been minted
    pub var totalSupply: UInt64

    pub struct CompetitionMembership {
        pub let competitionID: UInt64
        pub let squadID: UInt64
        pub let metadata: {String: AnyStruct}

        init(competitionID: UInt64, squadID: UInt64, metadata: {String: AnyStruct}) {
            self.competitionID = competitionID
            self.squadID = squadID
            self.metadata = metadata
        }
    }

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
        pub fun createOrUpdateCompetitionMembership(competitionID: UInt64, squadID: UInt64, metadata: {String: AnyStruct})
    }

    pub resource CompetitionAdmin: CompetitionAdminClaim {
        pub let name: String
    
        init() {
            self.name = "CompetitionAdminClaim"
        }

        // Competition

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

        pub fun updateCompetition(id: UInt64, type: String, name: String, metadata: {String: AnyStruct}) {
            pre {
                MFLCompetition.competitionsDatas[id] != nil : "Data not found"
            }
            let updatedCompetitionData = MFLCompetition.CompetitionData(
                id: id,
                type: type,
                name: name,
                metadata: metadata
            )
            MFLCompetition.competitionsDatas[id] = updatedCompetitionData
            emit Updated(id: id)
        }

        // CompetitionMembership

        // TODO separate create and update
        pub fun createOrUpdateCompetitionMembership(competitionID: UInt64, squadID: UInt64, metadata: {String: AnyStruct}) {
            // TODO check if squad exists ? dep to MFLClub ?
            let newCompetitionMembership = CompetitionMembership(competitionID: competitionID, squadID: squadID, metadata: metadata)

            // Update dict competitionsMembershipsByCompetitionId
            let toUpdateCompetitionMembershipCompetition = MFLCompetition.competitionsMembershipsByCompetitionId[competitionID] ?? {}
            toUpdateCompetitionMembershipCompetition.insert(key: squadID,newCompetitionMembership)
            MFLCompetition.competitionsMembershipsByCompetitionId[competitionID] = toUpdateCompetitionMembershipCompetition

            // Update dict competitionsMembershipsBySquadId
            let toUpdateCompetitionMembershipSquad = MFLCompetition.competitionsMembershipsBySquadId[squadID] ?? {}
            toUpdateCompetitionMembershipSquad.insert(key: competitionID,newCompetitionMembership)
            MFLCompetition.competitionsMembershipsBySquadId[squadID] = toUpdateCompetitionMembershipSquad

            emit CompetitionMembershipCreatedOrUpdated(competitionID: competitionID, squadID: squadID)
        }

        pub fun removeCompetitionMembershipSquad(competitionID: UInt64, squadID: UInt64) {
            // Remove squadID from competitionsMembershipsByCompetitionId dict
            let toUpdateCompetitionMembershipCompetition = MFLCompetition.competitionsMembershipsByCompetitionId[competitionID] ?? {}
            toUpdateCompetitionMembershipCompetition.remove(key: squadID)
            MFLCompetition.competitionsMembershipsByCompetitionId[competitionID] = toUpdateCompetitionMembershipCompetition

            // Remove squadID from competitionsMembershipsBySquadId dict
            let toUpdateCompetitionMembershipSquad = MFLCompetition.competitionsMembershipsBySquadId[squadID] ?? {}
            toUpdateCompetitionMembershipSquad.remove(key: competitionID)
            MFLCompetition.competitionsMembershipsBySquadId[squadID] = toUpdateCompetitionMembershipSquad

            emit CompetitionMembershipRemoved(competitionID: competitionID, squadID:squadID)
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
        self.competitionsMembershipsByCompetitionId = {}
        self.competitionsMembershipsBySquadId = {}
        
        emit ContractInitialized()
    }
}