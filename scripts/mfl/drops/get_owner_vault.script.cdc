import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

/** 
  This script returns the owner vault capability stored in MFLDrop.
  When someone buys a pack, the amount (usually FUSD) is sent to 
  the owner vault.
**/

pub fun main(): Capability<&AnyResource{FungibleToken.Receiver}>? {
    return MFLDrop.ownerVault
}