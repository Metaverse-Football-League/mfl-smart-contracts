import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/**
  This tx updates a player NFT metadata.
**/

transaction(
    id: UInt64,
    name: String,
    nationalities: [String],
    positions: [String],
    preferredFoot: String,
    ageAtMint: UInt32,
    height: UInt32,
    overall: UInt32,
    pace: UInt32,
    shooting: UInt32,
    passing: UInt32,
    dribbling: UInt32,
    defense: UInt32,
    physical: UInt32,
    goalkeeping: UInt32,
    potential: String,
    longevity: String,
    resistance: UInt32,
    ownerAddr: Address
) {
    let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy
    let ownerCollectionRef: &MFLPlayer.Collection

    prepare(acct: auth(BorrowValue) &Account) {
        self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        self.ownerCollectionRef = getAccount(ownerAddr).capabilities.borrow<&MFLPlayer.Collection>(
                    MFLPlayer.CollectionPublicPath
                ) ?? panic("Could not get receiver reference to the NFT Collection")
    }

    execute {
        let playerAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "PlayerAdminClaim") ?? panic("PlayerAdminClaim capability not found")
        let playerAdminClaimRef = playerAdminClaimCap.borrow<auth(MFLPlayer.PlayerAdminAction) &MFLPlayer.PlayerAdmin>() ?? panic("Could not borrow PlayerAdmin")

        let metadata: {String: AnyStruct} = {}
        metadata.insert(key: "name", name)
        metadata.insert(key: "nationalities", nationalities)
        metadata.insert(key: "positions", positions)
        metadata.insert(key: "preferredFoot", preferredFoot)
        metadata.insert(key: "ageAtMint", ageAtMint)
        metadata.insert(key: "height", height)
        metadata.insert(key: "overall", overall)
        metadata.insert(key: "pace", pace)
        metadata.insert(key: "shooting", shooting)
        metadata.insert(key: "passing", passing)
        metadata.insert(key: "dribbling", dribbling)
        metadata.insert(key: "defense", defense)
        metadata.insert(key: "physical", physical)
        metadata.insert(key: "goalkeeping", goalkeeping)
        metadata.insert(key: "potential", potential)
        metadata.insert(key: "longevity", longevity)
        metadata.insert(key: "resistance", resistance)

        playerAdminClaimRef.updatePlayerMetadata(
            id: id,
            metadata: metadata,
            collectionRefOptional: self.ownerCollectionRef
        )
    }
}
