import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

pub fun main(address: Address, playerID: UInt64): &MFLPlayer.NFT? {
    return MFLPlayer.fetch(from: address, itemID: playerID)
}
