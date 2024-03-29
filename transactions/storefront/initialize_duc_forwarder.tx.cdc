import FungibleToken from "../../contracts/_libs/FungibleToken.cdc"
import TokenForwarding from "../../contracts/_libs/TokenForwarding.cdc"
import DapperUtilityCoin from "../../contracts/_libs/DapperUtilityCoin.cdc"

/** 
  To receive the payment on-chain in DUC, the Storefront account must create a special resource called a Forwarder. 
  The Forwarder ensures that the Storefront is properly credited for purchases made by Dapper users. 
**/

transaction(dapperAccountAddress: Address) {

	prepare(acct: AuthAccount) {
		// Get a Receiver reference for the Dapper account that will be the recipient of the forwarded DUC
		let dapper = getAccount(dapperAccountAddress)
	  	let dapperDUCReceiver = dapper.getCapability(/public/dapperUtilityCoinReceiver)!

		// Create a new Forwarder resource for DUC and store it in the new account's storage
		let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapperDUCReceiver)
		acct.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)

		// Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
		acct.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver, target: /storage/dapperUtilityCoinReceiver)
	}
}