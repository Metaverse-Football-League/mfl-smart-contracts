import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

pub fun main(address: Address, playerID: UInt64): &MFLPlayer.NFT? {
    let playerCollectionRef = getAccount(address).getCapability<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow()
        ?? panic("Could not borrow the collection reference")
    let playerRef = playerCollectionRef.borrowPlayer(id: playerID)
    return playerRef
}
