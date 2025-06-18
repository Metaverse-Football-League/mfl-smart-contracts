import NonFungibleToken from 0x631e88ae7f1d7c20
import FungibleToken from 0x9a0766d93b6608b7
import OffersV2 from 0x8a5f647e58dde1ee
import DapperOffersV2 from 0x8a5f647e58dde1ee
import DapperUtilityCoin from 0x82ec283f88a62e65
import MFLPlayer from 0x683564e46977788a
import MFLOffersResolver from 0x683564e46977788a
import Resolver from 0x8a5f647e58dde1ee

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
