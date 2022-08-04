// TODO comments
import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MFLClub from "../clubs/MFLClub.cdc"

pub contract MFLUserPrivilege {

    // Events
    pub event ContractInitialized()

    // Named Paths


    pub enum UserPrivilegeType: UInt16 {
        pub case CLUB_MANAGER
        pub case CLUB_OWNER
        // pub case SQUAD_...
    }

    pub resource interface UserPrivilegeProxyPublic {
        access(contract) fun setClaimCapability(id: UInt64, type: UserPrivilegeType, capability: Capability)
        pub fun checkClaimsValidity(type: UserPrivilegeType): {UInt64: Bool}
    }

    pub resource UserPrivilegeProxy: UserPrivilegeProxyPublic {

        // dict claims capabilities by type and resource id
        access(self) let claimsCapabilities: { UserPrivilegeType: {UInt64: Capability} }

        access(contract) fun setClaimCapability(id: UInt64, type: UserPrivilegeType, capability: Capability) 
        {
            pre {
                capability.borrow<&{NonFungibleToken.CollectionPublic}>()!.getIDs().contains(id) : "resource id is not valid"
                self.checkClaimsType(type: type, capability: capability) : "type is not valid"
            }
            
            let claimsCapabalitiesType = self.claimsCapabilities[type] ?? {}
            switch type {
                case UserPrivilegeType.CLUB_OWNER:
                    claimsCapabalitiesType[id]= capability as! Capability<&MFLClub.Collection{MFLClub.Owner}>
                case UserPrivilegeType.CLUB_MANAGER:
                    claimsCapabalitiesType[id] = capability as! Capability<&MFLClub.Collection{MFLClub.Manager}>
                default:
                    panic("type not found") 
            }
            self.claimsCapabilities[type] = claimsCapabalitiesType
            //event ?
        }

        pub fun getClaimCapability(type: UserPrivilegeType, id: UInt64): Capability? {
            let claimsCapabalitiesType = self.claimsCapabilities[type] ?? {}
            return claimsCapabalitiesType[id]
        }

        pub fun checkClaimsValidity(type: UserPrivilegeType): {UInt64: Bool} {
            let claimsValidity: {UInt64: Bool} = {}
            let claimsCapabalitiesType = self.claimsCapabilities[type] ?? {}
            for key in claimsCapabalitiesType.keys {
                let isValid = self.checkClaimsType(type: type, capability: claimsCapabalitiesType[key]!)
                claimsValidity.insert(key: key, isValid)
            }
            return claimsValidity
        }

        access(self) fun checkClaimsType(type: UserPrivilegeType, capability: Capability): Bool {
            switch type {
                case UserPrivilegeType.CLUB_OWNER:
                    return capability.check<&MFLClub.Collection{MFLClub.Owner}>()
                case UserPrivilegeType.CLUB_MANAGER:
                    return capability.check<&MFLClub.Collection{MFLClub.Manager}>()
                default:
                    return false
            }
        }

        init() {
            self.claimsCapabilities = {}
            //event ?
        }
    }

    // Anyone can create an UserPrivilegeProxy, but can't do anything without Claims capabilities,
    // and only an UserPrivilegeRoot can provide that.
    pub fun createUserPrivilegeProxy(): @UserPrivilegeProxy {
        return <- create UserPrivilegeProxy()
    }

    // Resource that a user owns to be able to create setClaims and keep track of them
	pub resource UserPrivilegeRoot { // ? maybe we can sell this functionality ? if user pays he can share permissions ?

        // dictionary that contains the list of claim paths. These may not be valid anymore if the target resource
        // has been moved, destroyed or revoked for example
        access(self) let claimsCapabilitiesPath : { UserPrivilegeType: {UInt64: CapabilityPath} }
        
        // Set a Claim capabability for a given UserPrivilegeProxy
        pub fun setUserPrivilegeProxyClaimCapability(
            id: UInt64,
            type: UserPrivilegeType,
            userPrivilegeProxyRef: &{MFLUserPrivilege.UserPrivilegeProxyPublic},
            newCapability: Capability,
            path: CapabilityPath
        ) 
        {
            userPrivilegeProxyRef.setClaimCapability(id: id, type: type, capability: newCapability)
            // Save the new path
            let claimsCapabalitiesType = self.claimsCapabilitiesPath[type] ?? {}
            claimsCapabalitiesType[id] = path
            self.claimsCapabilitiesPath[type] = claimsCapabalitiesType
            //event ?
        }

        // This method should be called inside a revoke claim transaction
        pub fun removeClaimsCapabilities(id: UInt64, type: UserPrivilegeType) {
            let claimsCapabalitiesType = self.claimsCapabilitiesPath[type] ?? {}
            claimsCapabalitiesType.remove(key: id)
            self.claimsCapabilitiesPath[type] = claimsCapabalitiesType
        }

        init() {
            self.claimsCapabilitiesPath = {}
        }
	}

    // ? anyone can create userPrivilegeRoot ?
    pub fun createUserPrivilegeRoot(): @UserPrivilegeRoot {
        return <- create UserPrivilegeRoot()
    }

    init() {
        emit ContractInitialized()
    }

}