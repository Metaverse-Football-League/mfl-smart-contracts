import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

transaction(
    clubID: UInt64,
    foundationLicenseSerialNumber: UInt64,
    foundationLicenseCity: String,
    foundationLicenseCountry: String,
    foundationLicenseSeason: UInt32,
    foundationLicenseCID: String,
    squadID: UInt64,
    squadType: String,
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

        // let metadata: {String: AnyStruct} = {}
        //TODO insert metadata for clubNFT + central ledger club + squadNFT + central ledger squad


        let squadNFT <- squadAdminClaimRef.mintSquad(
            id: squadID,
            clubID: clubID,
            type: squadType,
            nftMetadata: {}, //nftMetadata,
            metadata: {}, //squadCentralMetadata
        )

        let foundationLicense = MFLClub.FoundationLicense(
            serialNumber: foundationLicenseSerialNumber,
            city: foundationLicenseCity,
            country: foundationLicenseCountry,
            season: foundationLicenseSeason,
            image: MetadataViews.IPFSFile(cid: foundationLicenseCID, path: nil)
        )

        let clubNFT <- clubAdminClaimRef.mintClub(
            id: clubID,
            foundationLicense: foundationLicense,
            squads: <- [<-squadNFT],
            nftMetadata: {}, //nftMetadata,
            metadata: {}, //clubCentralMetad
        )
        self.receiverRef.deposit(token: <- clubNFT)
    }

    post {
        MFLClub.getClubData(id: clubID) != nil : "Could not find club metadata in post"
        self.receiverRef.getIDs().contains(clubID) : "Could not find club in post"
        MFLClub.getSquadData(id: squadID) != nil : "Could not find squad metadata in post"
    }
}