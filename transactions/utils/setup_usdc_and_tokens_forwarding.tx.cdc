import DapperUtilityCoin from "../../contracts/_libs/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../../contracts/_libs/FlowUtilityToken.cdc"
import TokenForwarding from "../../contracts/_libs/TokenForwarding.cdc"
import FiatToken from "../../contracts/_libs/FiatToken.cdc"
import FungibleToken from "../../contracts/_libs/FungibleToken.cdc"

/*
This transaction will setup @TokenForwarding.Forwarder resources for the account submitting the transaction
that will forward Dapper Balance and Dapper Flow tokens to a selected Dapper Merchant address. That address
is the only argument to this transaction, and should be the dapper wallet address which you want funds to be
credited to.

Additionally, this transaction will also ensure that the submitting account has configured USDC (call
*/
transaction(dapperAddress: Address) {
    prepare(acct: AuthAccount) {
        let merchantAccount = getAccount(dapperAddress)
        if acct.borrow<&{FungibleToken.Receiver}>(from: /storage/flowUtilityTokenReceiver) == nil {
            let receiver = merchantAccount.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let forwarder <- TokenForwarding.createNewForwarder(recipient: receiver)
            acct.save(<-forwarder, to: /storage/flowUtilityTokenReceiver)
        }
        let futCap = acct.getCapability<&TokenForwarding.Forwarder{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        if !futCap.check() {
            // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
            acct.unlink(/public/flowUtilityTokenReceiver)
            acct.link<&TokenForwarding.Forwarder{FungibleToken.Receiver}>(
                /public/flowUtilityTokenReceiver,
                target: /storage/flowUtilityTokenReceiver
            )
        }
        if acct.borrow<&{FungibleToken.Receiver}>(from: /storage/dapperUtilityCoinReceiver) == nil {
            let receiver = merchantAccount.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let forwarder <- TokenForwarding.createNewForwarder(recipient: receiver)
            acct.save(<-forwarder, to: /storage/dapperUtilityCoinReceiver)
        }
        let ducCap = acct.getCapability<&TokenForwarding.Forwarder{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        if !ducCap.check() {
            acct.unlink(/public/dapperUtilityCoinReceiver)
            // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
            acct.link<&TokenForwarding.Forwarder{FungibleToken.Receiver}>(
                /public/dapperUtilityCoinReceiver,
                target: /storage/dapperUtilityCoinReceiver
            )
        }

        // also ensure USDC is configured properly
        if acct.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) == nil {
            let v <- FiatToken.createEmptyVault()
            acct.save(<- v, to: FiatToken.VaultStoragePath)

            // unlink usdc paths
            acct.unlink(FiatToken.VaultBalancePubPath)
            acct.unlink(FiatToken.VaultReceiverPubPath)

            // link usdc paths
            acct.link<&FiatToken.Vault{FungibleToken.Balance}>(FiatToken.VaultBalancePubPath, target: FiatToken.VaultStoragePath)
            acct.link<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
        }
    }
}
