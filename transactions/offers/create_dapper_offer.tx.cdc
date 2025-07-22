import NonFungibleToken from 0x1d7e57aa55817448
import FungibleToken from 0xf233dcee88fe0abe
import OffersV2 from 0xb8ea91944fd51c43
import DapperOffersV2 from 0xb8ea91944fd51c43
import DapperUtilityCoin from 0xead892083b3e2c6c
import MFLPlayer from 0x8ebcbfd516b1da27
import MFLOffersResolver from 0x8ebcbfd516b1da27
import Resolver from 0xb8ea91944fd51c43

transaction() {
    prepare(acct: auth(Storage, Capabilities) &Account) {
    	let dapperOffer <- DapperOffersV2.createDapperOffer()
		acct.storage.save(<-dapperOffer, to: DapperOffersV2.DapperOffersStoragePath)
		acct.capabilities.publish(
			acct.capabilities.storage.issue<&{DapperOffersV2.DapperOfferPublic}>(DapperOffersV2.DapperOffersStoragePath),
			at: DapperOffersV2.DapperOffersPublicPath
		)
    }

    execute {
    }
}
