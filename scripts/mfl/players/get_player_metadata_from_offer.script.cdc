import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

access(all) struct OfferV2Metadata {
	access(all) let amount: UFix64
	access(all) let royalties: {Address: UFix64}
	access(all) let params: {String: String}

	init(amount: UFix64, royalties: {Address: UFix64}, paramsString: {String: String}) {
        pre {
            paramsString.containsKey("nftId"): "paramsString must contain key 'serialNumber'"
        }

 		let nftId = UInt64.fromString(paramsString["nftId"]!)
                ?? panic("could not parse nftId as UInt64")
		let playerData = MFLPlayer.getPlayerData(id: nftId)
                ?? panic("could not get player data")
		let view = nft.resolveView(Type<MetadataViews.Display>())
		 	?? panic("could not get display view")
		let displayView = view as! MetadataViews.Display

 		paramsString["assetName"] =  playerData.metadata["name"] as! String? ?? ""
		paramsString["assetImageUrl"] = "https://d25q37b6uc8p6e.cloudfront.net/players/".concat(listingDetails.nftID.toString()).concat("/card.png")
		paramsString["assetDescription"] = display.description
        paramsString["typeId"] = "Type<@MFLPlayer.NFT>()"
		self.amount = amount
		self.royalties = royalties
		self.params = paramsString
	}
}

access(all) fun main(amount: UFix64, royalties: {Address: UFix64}, paramsString: {String: String}): OfferV2Metadata {
	return OfferV2Metadata(amount: amount, royalties: royalties, paramsString: paramsString)
}
