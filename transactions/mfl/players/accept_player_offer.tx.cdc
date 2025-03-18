import NonFungibleToken from "../../../contracts/_libs/NonFungibleToken.cdc"
import FungibleToken from "../../../contracts/_libs/FungibleToken.cdc"
import OffersV2 from "../../../contracts/_libs/OffersV2.cdc"
import DapperOffersV2 from "../../../contracts/_libs/DapperOffersV2.cdc"
import DapperUtilityCoin from "../../../contracts/_libs/DapperUtilityCoin.cdc"
import MetadataViews from "../../../contracts/_libs/MetadataViews.cdc"
import MFLPlayer from "../../../contracts/MFLPlayer.cdc"

transaction(nftID: UInt64, offerId: UInt64, dapperOfferAddress: Address) {
    let dapperOffer: &DapperOffersV2.DapperOffer
    let offer: &{OffersV2.OfferPublic}
    let receiverCapability: Capability<&{FungibleToken.Receiver}>

    prepare(signer: auth(Storage) &Account) {
        // Get the DapperOffers resource
        self.dapperOffer = getAccount(dapperOfferAddress).capabilities.get<&DapperOffersV2.DapperOffer>(DapperOffersV2.DapperOffersPublicPath).borrow()
            ?? panic("Could not borrow DapperOffer from provided address")
        // Set the fungible token receiver capabillity
        self.receiverCapability = signer.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        assert(self.receiverCapability.borrow() != nil, message: "Missing or mis-typed DapperUtilityCoin receiver")
        // Get the DapperOffer details
        self.offer = self.dapperOffer.borrowOffer(offerId: offerId)
            ?? panic("No Offer with that ID in DapperOffer")

		let details = self.offer.getDetails()

        // Get the NFT resource and withdraw the NFT from the signers account
        let nftCollection = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath)
            ?? panic("Cannot borrow NFT collection receiver from account")

		let nft <- (nftCollection.withdraw(withdrawID: nftID) as! @AnyResource) as! @{NonFungibleToken.NFT}

        self.offer.accept(
            item: <-nft,
            receiverCapability: self.receiverCapability
        )
    }

    execute {
        // delete the offer
        self.dapperOffer.cleanup(offerId: offerId)
    }
}
