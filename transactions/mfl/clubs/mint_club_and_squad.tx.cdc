import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"


/**
  This tx creates a Squad resource and a Club NFT
  and deposit it in the receiver collection.
  The Squad resource lives inside the Club NFT.
**/

transaction(
    clubID: UInt64,
    foundationLicenseSerialNumber: UInt64,
    foundationLicenseCity: String,
    foundationLicenseCountry: String,
    foundationLicenseSeason: UInt32,
    foundationLicenseCID: String,
    squadID: UInt64,
    squadType: String,
    competitionID: UInt64,
    leagueDivision: UInt32,
    receiverAddr: Address
) {
    let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy
    let receiverCollectionRef: &MFLClub.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        self.receiverCollectionRef = getAccount(receiverAddr).capabilities.borrow<&MFLClub.Collection>(
                MFLClub.CollectionPublicPath
            ) ?? panic("Could not get receiver reference to the NFT Collection")
    }

    execute {
        let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
        let clubAdminClaimRef = clubAdminClaimCap.borrow<auth(MFLClub.ClubAdminAction) &MFLClub.ClubAdmin>() ?? panic("Could not borrow ClubAdmin")
        let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
        let squadAdminClaimRef = squadAdminClaimCap.borrow<auth(MFLClub.SquadAdminAction) &MFLClub.SquadAdmin>() ?? panic("Could not borrow SquadAdmin")

        let competitionsMemberships: {UInt64: AnyStruct} = {}
        let leagueMembership: {String: AnyStruct} = {}
        leagueMembership.insert(key: "division", leagueDivision)
        competitionsMemberships.insert(key: competitionID, leagueMembership)

        let squadNFT <- squadAdminClaimRef.mintSquad(
            id: squadID,
            clubID: clubID,
            type: squadType,
            nftMetadata: {},
            metadata: {},
            competitionsMemberships: competitionsMemberships
        )


        let metadata: {String: AnyStruct} = {}
        metadata.insert(key: "foundationLicenseSerialNumber", foundationLicenseSerialNumber)
        metadata.insert(key: "foundationLicenseCity", foundationLicenseCity)
        metadata.insert(key: "foundationLicenseCountry", foundationLicenseCountry)
        metadata.insert(key: "foundationLicenseSeason", foundationLicenseSeason)
        metadata.insert(key: "foundationLicenseImage", MetadataViews.IPFSFile(cid: foundationLicenseCID, path: nil))

        let clubNFT <- clubAdminClaimRef.mintClub(
            id: clubID,
            squads: <- [<-squadNFT],
            nftMetadata: metadata,
            metadata: metadata
        )
        self.receiverCollectionRef.deposit(token: <- clubNFT)
    }

    post {
        self.receiverCollectionRef.getIDs().contains(clubID) : "Could not find club in post"
        MFLClub.getClubData(id: clubID) != nil : "Could not find club data in post"
        MFLClub.getSquadData(id: squadID) != nil : "Could not find squad data in post"
    }
}
