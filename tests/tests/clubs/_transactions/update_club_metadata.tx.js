export const UPDATE_CLUB_METADATA = `
    import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

    /** 
     This tx updates the metadata of a club.
    **/

    transaction(clubID: UInt64, clubName: String, clubDescription: String, logoVersion: String, division: UInt32, ownerAddrOptional: Address?) {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy
        let ownerCollectionRef: &MFLClub.Collection?

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
            if let ownerAddr = ownerAddrOptional {
                self.ownerCollectionRef = getAccount(ownerAddr).capabilities.borrow<&MFLClub.Collection>(
                    MFLClub.CollectionPublicPath
                ) ?? panic("Could not get receiver reference to the NFT Collection")
            } else {
                self.ownerCollectionRef = nil
            }
        }

        execute {
            let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
            let clubAdminClaimRef = clubAdminClaimCap.borrow<auth(MFLClub.ClubAdminAction) &MFLClub.ClubAdmin>() ?? panic("Could not borrow ClubAdmin")

            let metadata : {String: AnyStruct} = {}

            metadata.insert(key: "name", clubName)
            metadata.insert(key: "description", clubDescription)
            metadata.insert(key: "logoVersion", logoVersion)
            metadata.insert(key: "division", division)

            clubAdminClaimRef.updateClubMetadata(id: clubID, metadata: metadata, collectionRefOptional: self.ownerCollectionRef)
        }
    }
`;
