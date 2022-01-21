import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

pub fun main(): Capability<&AnyResource{FungibleToken.Receiver}>? {
    return MFLDrop.ownerVault
}