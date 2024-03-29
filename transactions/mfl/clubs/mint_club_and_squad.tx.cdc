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
    receiverAddress: Address
) {
    let adminProxyRef: &MFLAdmin.AdminProxy
    let receiverRef: &{NonFungibleToken.CollectionPublic}

    prepare(acct: AuthAccount) {
        self.adminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        let clubCollectionCap = getAccount(receiverAddress).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLClub.CollectionPublicPath)

        self.receiverRef = clubCollectionCap.borrow() ?? panic("Could not borrow receiver reference")
    }

    execute {
        let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
        let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
        let clubAdminClaimRef = clubAdminClaimCap.borrow<&{MFLClub.ClubAdminClaim}>() ?? panic("Could not borrow ClubAdminClaim")
        let squadAdminClaimRef = squadAdminClaimCap.borrow<&{MFLClub.SquadAdminClaim}>() ?? panic("Could not borrow SquadAdminClaim")

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
        self.receiverRef.deposit(token: <- clubNFT)
    }

    post {
        self.receiverRef.getIDs().contains(clubID) : "Could not find club in post"
        MFLClub.getClubData(id: clubID) != nil : "Could not find club data in post"
        MFLClub.getSquadData(id: squadID) != nil : "Could not find squad data in post"
    }
}
