import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import FungibleTokenSwitchboard from "../../../contracts/_libs/FungibleTokenSwitchboard.cdc"
import DapperUtilityCoin from "../../../contracts/_libs/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../../../contracts/_libs/FlowUtilityToken.cdc"

// This transaction is a template for a transaction that
// could be used by anyone to add a new vault wrapper
// capability to their switchboard resource
transaction {

    let ducForwarderCapability: Capability<&{FungibleToken.Receiver}>
    let futForwarderCapability: Capability<&{FungibleToken.Receiver}>
    let switchboardRef:  &FungibleTokenSwitchboard.Switchboard

    prepare(signer: AuthAccount) {

        self.ducForwarderCapability =
            signer.getCapability<&{FungibleToken.Receiver}>
                                (/public/dapperUtilityCoinReceiver)
        assert(self.ducForwarderCapability.check(),
            message: "Signer does not have a working fungible token receiver capability for DUC")

        self.futForwarderCapability =
            signer.getCapability<&{FungibleToken.Receiver}>
                                (/public/flowUtilityTokenReceiver)
        assert(self.futForwarderCapability.check(),
            message: "Signer does not have a working fungible token receiver capability for FUT")

        // Get a reference to the signers switchboard
        self.switchboardRef = signer.borrow<&FungibleTokenSwitchboard.Switchboard>
            (from: FungibleTokenSwitchboard.StoragePath)
            ?? panic("Could not borrow reference to switchboard")
    }

    execute {

        // Add the capability to the switchboard using addNewVault method
        self.switchboardRef.addNewVaultWrapper(capability: self.ducForwarderCapability, type: Type<@DapperUtilityCoin.Vault>())
        self.switchboardRef.addNewVaultWrapper(capability: self.futForwarderCapability, type: Type<@FlowUtilityToken.Vault>())

    }

}
