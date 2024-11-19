import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/**
  This tx updates the metadata of a club.
**/

 // ! TODO AnyStruct not valid in fcl arg - we have to define explicitly the metadata
transaction(clubID: UInt64, metadata: {String: AnyStruct}, ownerAddr: Address) {
    let adminProxyRef: &MFLAdmin.AdminProxy
    let ownerCollectionRef: &MFLClub.Collection

    prepare(acct: AuthAccount) {
        self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
		self.ownerCollectionRef = getAccount(ownerAddr).capabilities.borrow<&MFLClub.Collection>(
					MFLClub.CollectionPublicPath
				) ?? panic("Could not get receiver reference to the NFT Collection")
    }

    execute {
        let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
        let clubAdminClaimRef = clubAdminClaimCap.borrow<&{MFLClub.ClubAdminClaim}>() ?? panic("Could not borrow ClubAdminClaim")

        clubAdminClaimRef.updateClubMetadata(id: clubID, metadata: metadata, collectionRefOptional: self.ownerCollectionRef)
    }
}
