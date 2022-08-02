//TODO comments

pub contract MFLSquad {

    // Events
    pub event ContractInitialized()
    pub event Minted(id: UInt64)

    // Named Paths
    pub let SquadAdminStoragePath: StoragePath

    access(self) let squads: @{UInt64: Squad}
    access(self) let squadsDatas: {UInt64: SquadData}

    // The total number of Clubs that have been minted
    pub var totalSupply: UInt64

    pub enum SquadType: UInt16 {
        pub case U20
        pub case RESERVE
        pub case PRIMARY
        pub case SENIOR
    }

    pub struct LeagueMembership {
        pub let leagueID: UInt64
        pub let squadID: UInt64
        pub let division: UInt32

        init(leagueID: UInt64, squadID: UInt64, division: UInt32) {
            self.leagueID = leagueID
            self.squadID = squadID
            self.division = division
        }
    }

    pub struct SquadData {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let type: SquadType
        access(contract) var metadata: {String: AnyStruct}

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
        pub let type: SquadType
        access(self) let leaguesMemberships: [LeagueMembership] // ? not here because squad will be stored in user account, 

        init(id: UInt64, clubID: UInt64, type: SquadType, leaguesMemberships: [LeagueMembership]) {
            self.id = id
            self.clubID = clubID
            self.type = type
            self.leaguesMemberships = leaguesMemberships
        }

        destroy () {
            // ? remove data in central ledger ? (not the case for player for ex.)
        }
    }


    // pub let getSquadLeagueMembership() {

    // }

    // This interface allows any account that has a private capability to a SquadAdminClaim to call the methods below
    pub resource interface SquadAdminClaim {
        pub let name: String
        pub fun mintSquad(id: UInt64, clubID: UInt64, type: SquadType, leaguesMemberships: [LeagueMembership]): @Squad
    }

    pub resource SquadAdmin: SquadAdminClaim {
        pub let name: String

        init() {
            self.name = "SquadAdminClaim"
        }

        pub fun mintSquad(id: UInt64, clubID: UInt64, type: SquadType, leaguesMemberships: [LeagueMembership]): @Squad {
            let squad <- create Squad(
                id: id,
                clubID: clubID,
                type: type,
                leaguesMemberships: leaguesMemberships
            )
            // update metadata
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
        self.squads <- {}
        self.squadsDatas = {}

        emit ContractInitialized()
    }
}