/**
  This contract contains the MFL Admin logic.The idea is that any account can create an adminProxy,
  but only an AdminRoot in possession of Claims can share them with that admin proxy (using private capabilities).
**/

pub contract MFLAdmin {

    // Events
    pub event ContractInitialized()
    pub event AdminRootCreated(by: Address?)

    // Named Paths
    pub let AdminRootStoragePath: StoragePath
    pub let AdminProxyStoragePath: StoragePath
    pub let AdminProxyPublicPath: PublicPath

    // Interface that an AdminProxy will expose to be able to receive Claims capabilites from an AdminRoot
    pub resource interface AdminProxyPublic {
        access(contract) fun setClaimCapability(name: String, capability: Capability)
    }

    pub resource AdminProxy: AdminProxyPublic {

        // Dictionary of all Claims Capabilities stored in an AdminProxy
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

    // Anyone can create an AdminProxy, but can't do anything without Claims capabilities,
    // and only an AdminRoot can provide that.
    pub fun createAdminProxy(): @AdminProxy {
        return <- create AdminProxy()
    }

    // Resource that an admin owns to be able to create new AdminRoot or to set Claims
	pub resource AdminRoot {

        // Create a new AdminRoot resource and returns it
        // Only if really needed ! One AdminRoot should be enough for all the logic in MFL
        pub fun createNewAdminRoot(): @AdminRoot {
            emit AdminRootCreated(by: self.owner?.address)
            return <- create AdminRoot()
        }

        // Set a Claim capabability for a given AdminProxy
        pub fun setAdminProxyClaimCapability(name: String, adminProxyRef: &{MFLAdmin.AdminProxyPublic}, newCapability: Capability) {
            adminProxyRef.setClaimCapability(name: name, capability: newCapability)
        }
	}

    init() {
        // Set our named paths
        self.AdminRootStoragePath = /storage/MFLAdminRoot
        self.AdminProxyStoragePath = /storage/MFLAdminProxy
        self.AdminProxyPublicPath = /public/MFLAdminProxy

        // Create an AdminRoot resource and save it to storage
        let adminRoot <- create AdminRoot()
        self.account.save(<- adminRoot, to: self.AdminRootStoragePath)

        emit ContractInitialized()
    }

}
