import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

pub fun main(address: Address): [UInt64] {
    let playerCollectionRef = getAccount(address).getCapability<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow()
        ?? panic("Could not borrow the collection reference")
    return playerCollectionRef.getIDs()
}
