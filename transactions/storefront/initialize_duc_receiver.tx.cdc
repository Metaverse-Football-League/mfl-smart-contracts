import FungibleToken from "../../contracts/_libs/FungibleToken.cdc"
import DapperUtilityCoin from "../../contracts/_libs/DapperUtilityCoin.cdc"

/**
  To receive the payment on-chain in DUC, the Storefront account must create a special resource called a Forwarder.
  The Forwarder ensures that the Storefront is properly credited for purchases made by Dapper users.
**/

transaction() {

	prepare(acct: auth(SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {
		let ducVault <- DapperUtilityCoin.createEmptyVault(vaultType: Type<@DapperUtilityCoin.Vault>())
		acct.storage.save(<-ducVault, to: /storage/dapperUtilityCoinVault)
        let vaultCap = acct.capabilities.storage.issue<&DapperUtilityCoin.Vault>(/storage/dapperUtilityCoinVault)
        acct.capabilities.publish(vaultCap, at: /public/dapperUtilityCoinReceiver)
	}
}
