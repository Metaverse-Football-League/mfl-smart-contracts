/**
  This contract contains the MFL Admin logic.The idea is that any account can create an adminProxy,
  but only an AdminRoot in possession of Claims can share them with that admin proxy (using private capabilities).
**/

access(all)
contract MFLAdmin { 
	
    access(all) entitlement AdminRootActions

	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event AdminRootCreated(by: Address?)
	
	// Named Paths
	access(all)
	let AdminRootStoragePath: StoragePath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	// MFL Royalty Address
	access(all)
	fun royaltyAddress(): Address { 
		return 0xa654669bd96b2014
	}
	
	// Interface that an AdminProxy will expose to be able to receive Claims capabilites from an AdminRoot
	access(all)
	resource interface AdminProxyPublic { 
		access(contract)
		fun setClaimCapability(name: String, capability: Capability)
	}
	
	access(all)
	resource AdminProxy: AdminProxyPublic { 
		
		// Dictionary of all Claims Capabilities stored in an AdminProxy
		access(contract)
		let claimsCapabilities: {String: Capability}
		
		access(contract)
		fun setClaimCapability(name: String, capability: Capability) { 
			self.claimsCapabilities[name] = capability
		}
		
		access(all)
		view fun getClaimCapability(name: String): Capability? { 
			return self.claimsCapabilities[name]
		}
		
		init() { 
			self.claimsCapabilities = {} 
		}
	}
	
	// Anyone can create an AdminProxy, but can't do anything without Claims capabilities,
	// and only an AdminRoot can provide that.
	access(all)
	fun createAdminProxy(): @AdminProxy { 
		return <-create AdminProxy()
	}
	
	// Resource that an admin owns to be able to create new AdminRoot or to set Claims
	access(all)
	resource AdminRoot { 
		
		// Create a new AdminRoot resource and returns it
		// Only if really needed ! One AdminRoot should be enough for all the logic in MFL
		access(AdminRootActions)
		fun createNewAdminRoot(): @AdminRoot { 
			emit AdminRootCreated(by: self.owner?.address)
			return <-create AdminRoot()
		}
		
		// Set a Claim capabability for a given AdminProxy
		access(AdminRootActions)
		fun setAdminProxyClaimCapability(
			name: String,
			adminProxyRef: &{MFLAdmin.AdminProxyPublic},
			newCapability: Capability
		) { 
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
		self.account.storage.save(<-adminRoot, to: self.AdminRootStoragePath)
		emit ContractInitialized()
	}
}