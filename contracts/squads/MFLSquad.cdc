//TODO comments

pub contract MFLSquad {

    // Events
    pub event ContractInitialized()
    pub event Minted(id: UInt64)
    pub event Destroyed(id: UInt64)

    // Named Paths
    pub let SquadAdminStoragePath: StoragePath

    access(self) let squadsDatas: {UInt64: SquadData}

    // The total number of Squads that have been minted
    pub var totalSupply: UInt64

    pub enum SquadType: UInt16 {  // ? delete because type is string
        pub case PRIMARY
    }

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

    pub struct SquadData {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let type: SquadType
        access(contract) let metadata: {String: AnyStruct}
        // TODO add in metadata competitionsMemberships : { competitionId: {competitionId: ..., squadId: ..., metadata: {toto: ""} } }

        init(id: UInt64, clubID: UInt64, type: SquadType, metadata: {String: AnyStruct}) {
            self.id = id
            self.clubID = clubID
            self.type = type
            self.metadata = metadata
        }
    }

    pub resource Squad {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let type: SquadType // TODO string
        access(self) let metadata: {String: AnyStruct} 

        init(id: UInt64, clubID: UInt64, type: SquadType, metadata: {String: AnyStruct}) {
            self.id = id
            self.clubID = clubID
            self.type = type
            self.metadata = metadata
            MFLSquad.totalSupply = MFLSquad.totalSupply + (1 as UInt64)
            emit Minted(id: self.id)
        }

        destroy() {
            // ? remove data in central ledger ? (not the case for player for ex.)
            emit Destroyed(id: self.id)
        }
    }


    // This interface allows any account that has a private capability to a SquadAdminClaim to call the methods below
    pub resource interface SquadAdminClaim {
        pub let name: String
        pub fun mintSquad(
            id: UInt64,
            clubID: UInt64,
            type: SquadType,
            nftMetadata: {String: AnyStruct},
            centralMetadata: {String: AnyStruct}
        ): @Squad
    }

    pub resource SquadAdmin: SquadAdminClaim {
        pub let name: String

        init() {
            self.name = "SquadAdminClaim"
        }

        pub fun mintSquad(
            id: UInt64,
            clubID: UInt64,
            type: SquadType,
            nftMetadata: {String: AnyStruct},
            centralMetadata: {String: AnyStruct}
        ): @Squad {
            let squad <- create Squad(
                id: id,
                clubID: clubID,
                type: type,
                metadata: nftMetadata
            )
            MFLSquad.squadsDatas[id] = MFLSquad.SquadData(
                id: id,
                clubID:clubID,
                type: type,
                metadata: centralMetadata
            ) 
            return <- squad
        }

        pub fun createSquadAdmin(): @SquadAdmin {
            return <- create SquadAdmin()
        } 
    }


    init() {
        // Set our named paths
        self.SquadAdminStoragePath = /storage/MFLSquadAdmin

        // Create SquadAdmin resource and save it to storage
        self.account.save(<- create SquadAdmin() , to: self.SquadAdminStoragePath)

        // Initialize contract fields
        self.totalSupply = 0
        self.squadsDatas = {}

        emit ContractInitialized()
    }
}