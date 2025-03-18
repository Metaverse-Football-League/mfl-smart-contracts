import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import OffersV2 from "../../../contracts/_libs/OffersV2.cdc"
import DapperOffersV2 from "../../../contracts/_libs/DapperOffersV2.cdc"
import DapperUtilityCoin from "../../../contracts/_libs/DapperUtilityCoin.cdc"
import Resolver from "../../../contracts/_libs/Resolver.cdc"
import MFLOffersResolver from "../../../contracts/MFLOffersResolver.cdc"
import MFLPlayer from "../../../contracts/MFLPlayer.cdc"

transaction(
    amount: UFix64,
    royalties: {Address: UFix64},
    playerId: UInt64,
    expiry: UInt64,
) {
	var nftReceiver: Capability<&MFLPlayer.Collection>
	let dapperOffer: auth(DapperOffersV2.Manager) &DapperOffersV2.DapperOffer
	let ducVaultRef: Capability<auth(FungibleToken.Withdraw) &DapperUtilityCoin.Vault>
	let resolverCapability: Capability<&{Resolver.ResolverPublic}>
	let tokenAdminCollection: Capability<auth(DapperOffersV2.ProxyManager) &DapperOffersV2.DapperOffer>

    prepare(signer: auth(Storage, Capabilities) &Account, dapper: auth(Storage, Capabilities) &Account) {
		if signer.storage.borrow<&MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath) == nil {
			let collection <- MFLPlayer.createEmptyCollection(nftType: Type<@MFLPlayer.NFT>())
			signer.storage.save(<-collection, to: MFLPlayer.CollectionStoragePath)
		}

        self.nftReceiver = signer.capabilities.get<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
		if !self.nftReceiver.check() {
			signer.capabilities.unpublish(MFLPlayer.CollectionPublicPath)
			let collectionCap = signer.capabilities.storage.issue<&MFLPlayer.Collection>(MFLPlayer.CollectionStoragePath)
			signer.capabilities.publish(collectionCap, at: MFLPlayer.CollectionPublicPath)
			self.nftReceiver = signer.capabilities.get<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
        }

        let dapperOfferType = Type<@DapperOffersV2.DapperOffer>()

        // Link the DapperOffer resource
        if signer.storage.borrow<&DapperOffersV2.DapperOffer>(from: DapperOffersV2.DapperOffersStoragePath) == nil {
            let dapperOffer <- DapperOffersV2.createDapperOffer()
            signer.storage.save(<-dapperOffer, to: DapperOffersV2.DapperOffersStoragePath)
            signer.capabilities.publish(
                signer.capabilities.storage.issue<&{DapperOffersV2.DapperOfferPublic}>(DapperOffersV2.DapperOffersStoragePath),
                at: DapperOffersV2.DapperOffersPublicPath
            )

            let managerStoragePath = /storage/mflDapperOfferManager
            let cap = signer.storage.copy<Capability<auth(DapperOffersV2.Manager) &{DapperOffersV2.DapperOfferManager}>>(from: managerStoragePath)
            if cap?.check() != true {
                let managerCap = signer.capabilities.storage.issue<auth(DapperOffersV2.Manager) &{DapperOffersV2.DapperOfferManager}>(DapperOffersV2.DapperOffersStoragePath)
                signer.storage.save(managerCap, to: managerStoragePath)
            }
        }

        // DapperOfferProxyManager Setup
        let proxyStoragePath = /storage/mflDapperOfferProxy
        let copiedProxy = signer.storage.copy<Capability<auth(DapperOffersV2.ProxyManager) &DapperOffersV2.DapperOffer>>(from: proxyStoragePath)
        if copiedProxy?.check() == true {
            self.tokenAdminCollection = copiedProxy!
        } else {
            self.tokenAdminCollection = signer.capabilities.storage.issue<auth(DapperOffersV2.ProxyManager) &DapperOffersV2.DapperOffer>(DapperOffersV2.DapperOffersStoragePath)
            signer.storage.load<AnyStruct>(from: proxyStoragePath)
            signer.storage.save(self.tokenAdminCollection, to: proxyStoragePath)
        }

        if dapper.storage.borrow<&DapperOffersV2.DapperOffer>(from: DapperOffersV2.DapperOffersStoragePath) == nil {
            let dapperOffer <- DapperOffersV2.createDapperOffer()
            dapper.storage.save(<-dapperOffer, to: DapperOffersV2.DapperOffersStoragePath)
            dapper.capabilities.publish(
                dapper.capabilities.storage.issue<&{DapperOffersV2.DapperOfferPublic}>(DapperOffersV2.DapperOffersStoragePath),
                at: DapperOffersV2.DapperOffersPublicPath
            )

            let proxyManagerStoragePath = /storage/dapperProxyManager
            let proxyCap = dapper.capabilities.storage.issue<auth(DapperOffersV2.ProxyManager) &{DapperOffersV2.DapperOfferManager, DapperOffersV2.DapperOfferProxyManager}>(DapperOffersV2.DapperOffersStoragePath)
            dapper.storage.save(proxyCap, to: proxyManagerStoragePath)
        }

        // Setup Proxy Cancel for Dapper
        let capabilityReceiver = dapper.capabilities.get<&{DapperOffersV2.DapperOfferPublic}>(/public/DapperOffersV2).borrow()
            ?? panic("Could not borrow capability receiver reference")
        capabilityReceiver.addProxyCapability(account: signer.address, cap: self.tokenAdminCollection)

        // Get the capability to the offer creators NFT collection
        self.nftReceiver = signer.capabilities.get<&MFLPlayer.Collection>(MFLPlayer.CollectionPublicPath)
        assert(self.nftReceiver.check(), message: "Missing or mis-typed collection receiver")

        self.dapperOffer = signer.storage.borrow<auth(DapperOffersV2.Manager) &DapperOffersV2.DapperOffer>(from: DapperOffersV2.DapperOffersStoragePath)
            ?? panic("Missing or mis-typed DapperOffersV2.DapperOffer")
        // Get the capability to the DUC vault

        let ducCapStoragePath = /storage/mflDucProvider
        let copiedDucProvider = dapper.storage.copy<Capability<auth(FungibleToken.Withdraw) &DapperUtilityCoin.Vault>>(from: ducCapStoragePath)
        if copiedDucProvider?.check() == true {
            self.ducVaultRef = copiedDucProvider!
        } else {
            self.ducVaultRef = dapper.capabilities.storage.issue<auth(FungibleToken.Withdraw) &DapperUtilityCoin.Vault>(/storage/dapperUtilityCoinVault)
            dapper.storage.save(self.ducVaultRef, to: ducCapStoragePath)
            let initalDucSupplyee = self.ducVaultRef.borrow()!.balance
        }

        assert(self.ducVaultRef.check() != nil, message: "Missing or mis-typed DapperUtilityCoin provider")

        self.resolverCapability = MFLOffersResolver.getResolverCap()
    }

    execute {
        var royaltysList: [OffersV2.Royalty] = []
        for k in royalties.keys {
            royaltysList.append(OffersV2.Royalty(
                receiver: getAccount(k).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver),
                amount: royalties[k]!
            ))
        }

        let typeId = "A.179b6b1cb6755e31.MFLPlayer.NFT"

		let offerParamsString: {String: String} = {}
        offerParamsString.insert(key: "nftId", playerId.toString())
        offerParamsString.insert(key: "resolver", "0")
        offerParamsString.insert(key: "_type", "NFT")
        offerParamsString.insert(key: "typeId", typeId)

        let offerParamsUInt64: {String: UInt64} = { "expiry": expiry }

        self.dapperOffer.createOffer(
            vaultRefCapability: self.ducVaultRef,
            nftReceiverCapability: self.nftReceiver,
            nftType: CompositeType(typeId)!,
            amount: amount,
            royalties: royaltysList,
            offerParamsString: offerParamsString,
            offerParamsUFix64: {},
            offerParamsUInt64: offerParamsUInt64,
            resolverCapability: self.resolverCapability
        )
    }
}
