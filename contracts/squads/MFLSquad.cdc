//TODO comments

pub contract MFLSquad {

    // Events
    pub event ContractInitialized()
    pub event Minted(id: UInt64)

    access(self) let squads: @{UInt64: Squad}

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

    pub resource Squad {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let type: String // TODO enum ?
        access(contract) let leaguesMemberships: [LeagueMembership]

        init(id: UInt64, clubID: UInt64, type: String, leaguesMemberships: [LeagueMembership]) {
            self.id = id
            self.clubID = clubID
            self.type = type
            self.leaguesMemberships = leaguesMemberships
        }
    }

    // pub let getSquadLeagueMembership() {

    // }

    init() {
        self.squads <- {}
        emit ContractInitialized()
    }
}