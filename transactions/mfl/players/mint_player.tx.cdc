import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"

/**
  This tx mints a new player NFT given a certain number of parameters,
  and deposit it in the receiver collection.
**/

transaction(
    id: UInt64,
    season: UInt32,
    folderCID: String,
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
    receiverAddress: Address
) {
    let playerAdminProxyRef: &MFLAdmin.AdminProxy
    let receiverRef: &{NonFungibleToken.CollectionPublic}

    prepare(acct: AuthAccount) {
        self.playerAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        let playerCollectionCap = getAccount(receiverAddress).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLPlayer.CollectionPublicPath)
        self.receiverRef = playerCollectionCap.borrow() ?? panic("Could not borrow receiver reference")
    }

    execute {
        let playerAdminClaimCap = self.playerAdminProxyRef.getClaimCapability(name: "PlayerAdminClaim") ?? panic("PlayerAdminClaim capability not found")
        let playerAdminClaimRef = playerAdminClaimCap.borrow<&{MFLPlayer.PlayerAdminClaim}>() ?? panic("Could not borrow PlayerAdminClaim")

        let metadata: {String: AnyStruct} = {}
        metadata.insert(key: "name", name)
        metadata.insert(key: "overall", overall)
        metadata.insert(key: "nationalities", nationalities)
        metadata.insert(key: "positions", positions)
        metadata.insert(key: "preferredFoot", preferredFoot)
        metadata.insert(key: "ageAtMint", ageAtMint)
        metadata.insert(key: "height", height)
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

        let image = MetadataViews.IPFSFile(cid: folderCID, path: nil)
        let playerNFT <- playerAdminClaimRef.mintPlayer(
            id: id,
            metadata: metadata,
            season: season,
            image: image,
        )
        self.receiverRef.deposit(token: <- playerNFT)
    }

    post {
        MFLPlayer.getPlayerData(id: id) != nil: "Could not find player metadata in post"
        self.receiverRef.getIDs().contains(id): "Could not find player in post"
    }
}
