pub contract MFLAdmin {

    // Events
    pub event ContractInitialized()
    pub event AdminRootCreated(by: Address?)

    // Named Paths
    pub let AdminRootStoragePath: StoragePath
    pub let AdminProxyStoragePath: StoragePath
    pub let AdminProxyPublicPath: PublicPath

    pub resource interface AdminProxyPublic {
        access(contract) fun setClaimCapability(name: String, capability: Capability)
    }

    pub resource AdminProxy: AdminProxyPublic {

        access(contract) let claimsCapabilities: {String: Capability}

        access(contract) fun setClaimCapability(name: String, capability: Capability) {
            self.claimsCapabilities[name] = capability
        }

        pub fun getClaimCapability(name: String): Capability? {
            return self.claimsCapabilities[name]
        }

        init() {
            self.claimsCapabilities = {}
        }
    }

    // Anyone can call this, but the AdminProxy can't do anything without a Claims capability,
    // and only the admin can provide that.
    pub fun createAdminProxy(): @AdminProxy {
        return <- create AdminProxy()
    }

    // Resource that an admin owns to be able to create new Admin or to create Claims
	pub resource AdminRoot {

        // Create a new Admin resource and returns it
        // Only if really needed ! One AdminRoot should be enough for all the logic in MFL
        pub fun createNewAdminRoot(): @AdminRoot {
            emit AdminRootCreated(by: self.owner?.address)
            return <- create AdminRoot()
        }

        pub fun setAdminProxyClaimCapability(name: String, adminProxyRef: &{MFLAdmin.AdminProxyPublic}, newCapability: Capability) {
            adminProxyRef.setClaimCapability(name: name, capability: newCapability)
        }
	}

    init() {
        self.AdminRootStoragePath = /storage/MFLAdminRoot
        self.AdminProxyStoragePath = /storage/MFLAdminProxy
        self.AdminProxyPublicPath = /public/MFLAdminProxy

        // Create an AdminRoot resource and save it to storage
        let adminRoot <- create AdminRoot()

        self.account.save(<- adminRoot, to: self.AdminRootStoragePath)

        emit ContractInitialized()
    }

}
