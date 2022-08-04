// TODO comments
import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MFLClub from "../clubs/MFLClub.cdc"

pub contract MFLAdmin {

    // Events
    pub event ContractInitialized()
    pub event AdminRootCreated(by: Address?)

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

        // clubs claims
        access(self) let claimsClubsOwnerCapabilities: {UInt64: Capability<&MFLClub.Collection{MFLClub.Owner}>}
        access(self) let claimsClubsManagerCapabilities: {UInt64: Capability<&MFLClub.Collection{MFLClub.Manager}>}

        // squad claims
        // ...

        access(contract) fun setClaimCapability(id: UInt64, type: UserPrivilegeType, capability: Capability) 
        {
            pre {
                capability.borrow<&{NonFungibleToken.CollectionPublic}>()!.getIDs().contains(id) : "resource id is not valid"
            }
            switch type {
                case UserPrivilegeType.CLUB_OWNER:
                    assert(capability.check<&MFLClub.Collection{MFLClub.Owner}>(), message: "type is not valid")
                    self.claimsClubsOwnerCapabilities[id] = capability as! Capability<&MFLClub.Collection{MFLClub.Owner}>
                case UserPrivilegeType.CLUB_MANAGER:
                    assert(capability.check<&MFLClub.Collection{MFLClub.Manager}>(), message: "type is not valid")
                    self.claimsClubsManagerCapabilities[id] = capability as! Capability<&MFLClub.Collection{MFLClub.Manager}>
                default:
                    panic("type not found") 
            }
        }

        pub fun getClaimCapability(type: UserPrivilegeType, id: UInt64): Capability? {
            switch type {
                case UserPrivilegeType.CLUB_OWNER:
                    return self.claimsClubsOwnerCapabilities[id]
                case UserPrivilegeType.CLUB_MANAGER:
                    return self.claimsClubsManagerCapabilities[id]
                default:
                    return nil
            }
        }

        access(self) fun check(_ claimsCapabilities: {UInt64: Capability}): {UInt64: Bool} {
            let claimsValidity: {UInt64: Bool} = {}
            for key in claimsCapabilities.keys {
                // let isValid = self.claimsClubsOwnerCapabilities[key]!.check()// TODO no because claimsCapabilities does not have the right type
                let isValid = claimsCapabilities[key]!.check<capabilityType>()
                claimsValidity.insert(key: key, isValid)
            }
            return claimsValidity
        }

        pub fun checkClaimsValidity(type: UserPrivilegeType): {UInt64: Bool} {
            let claimsValidity: {UInt64: Bool} = {}
            switch type {
                case UserPrivilegeType.CLUB_OWNER:
                    return self.check(self.claimsClubsOwnerCapabilities)
                case UserPrivilegeType.CLUB_MANAGER:
                    return self.check(self.claimsClubsManagerCapabilities)
                default:
                    return {}
            }
        }

        init() {
            self.claimsClubsOwnerCapabilities = {}
            self.claimsClubsManagerCapabilities = {}
        }
    }

    // Anyone can create an AdminProxy, but can't do anything without Claims capabilities,
    // and only an AdminRoot can provide that.
    // pub fun createAdminProxy(): @AdminProxy {
    //     return <- create AdminProxy()
    // }

    // Resource that an admin owns to be able to create new AdminRoot or to set Claims
	pub resource UserPrivilegeRoot { // ? maybe we can sell this functionality ? if user pays he can share permissions

        // Create a new AdminRoot resource and returns it
        // Only if really needed ! One AdminRoot should be enough for all the logic in MFL
        // pub fun createNewAdminRoot(): @AdminRoot {
        //     emit AdminRootCreated(by: self.owner?.address)
        //     return <- create AdminRoot()
        // }

        // // Set a Claim capabability for a given AdminProxy
        // pub fun setAdminProxyClaimCapability(name: String, adminProxyRef: &{MFLAdmin.AdminProxyPublic}, newCapability: Capability) {
        //     adminProxyRef.setClaimCapability(name: name, capability: newCapability)
        // }
	}

    init() {
    

        emit ContractInitialized()
    }

}

// User sets his proxy
// Tx to give claim to a user
// emit an event to store in DB claims associated to this user
