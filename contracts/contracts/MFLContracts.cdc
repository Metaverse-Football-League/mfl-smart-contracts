//TODO comments

pub contract MFLContracts {
    // Events
    pub event ContractInitialized()
    pub event Minted(id: UInt64)

    access(self) let contracts: @{UInt64: Contract}

    pub resource Contract {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let squadID: UInt64
        pub let expirationDate: UInt64 // ?UFix64 like getCurrentBlock().timestamp 
        // pub let revenuesShares: [RevenueShare] [{receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64}]
        // salePaymentVaultType: Type ? (our own token in the future)

        init(id: UInt64, clubID: UInt64, squadID: UInt64, expirationDate: UInt64) {
            self.id = id
            self.clubID = clubID
            self.squadID = squadID
            self.expirationDate = expirationDate
        }
    }

    init() {
        self.contracts <- {}
        emit ContractInitialized()
    }
}