import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/** 
  This tx mints a new player NFT given a certain number of parameters.
**/

transaction(
    id: UInt64,
    season: UInt32,
    ipfsURI: String,
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
    resistance: UInt32,
) {
    let playerAdminProxyRef: &MFLAdmin.AdminProxy
    let receiverRef: &{MFLPlayer.CollectionPublic}

    prepare(acct: AuthAccount) {
        self.playerAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        let playerCollectionCap = getAccount(acct.address).getCapability<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath)
        self.receiverRef = playerCollectionCap.borrow() ?? panic("Could not borrow receiver reference")
    }

    execute {
        let playerAdminClaimCap = self.playerAdminProxyRef.getClaimCapability(name: "PlayerAdminClaim") ?? panic("PlayerAdminClaim capability not found")
        let playerAdminClaimRef = playerAdminClaimCap.borrow<&{MFLPlayer.PlayerAdminClaim}>() ?? panic("Could not borrow PlayerAdminClaim")

        let metadata: {String: AnyStruct} = {}
        metadata.insert(key: "name", name)
        metadata.insert(key: "overall", overall)
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
        metadata.insert(key: "resistance", resistance)

        let playerNFT <- playerAdminClaimRef.mintPlayer(
            id: id,
            metadata: metadata,
            season: season,
            ipfsURI: ipfsURI,
        )
        self.receiverRef.deposit(token: <- playerNFT)
    }

    post {
        MFLPlayer.getPlayerMetadata(playerID: id) != nil: "Could not find player metadata in post"
        self.receiverRef.getIDs().contains(id): "Could not find player in post"
    }
}
