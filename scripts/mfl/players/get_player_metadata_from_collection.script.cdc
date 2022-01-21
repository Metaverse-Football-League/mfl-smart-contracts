import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

pub fun main(address: Address, playerID: UInt64): MFLPlayer.PlayerMetadata? {
    let playerNFT = MFLPlayer.fetch(from: address, itemID: playerID)
    return playerNFT != nil ? playerNFT!.getMetadata() : nil
}
