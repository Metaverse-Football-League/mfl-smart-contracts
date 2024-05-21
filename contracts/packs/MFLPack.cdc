import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MFLViews from "./MFLViews.cdc"

import MFLAdmin from "./MFLAdmin.cdc"

import MFLPackTemplate from "./MFLPackTemplate.cdc"

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows to mint packs (NFTs), which can then be opened. A pack
  is always linked to a packTemplate (see MFLPackTemplate contract for more info).
**/

access(all)
contract MFLPack: NonFungibleToken { 
	
	// Entitlements
    access(all)
	entitlement PackAdminAction

	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Opened(id: UInt64, from: Address?)
	
	access(all)
	event Minted(id: UInt64, packTemplateID: UInt64, from: Address?)
	
	access(all)
	event Destroyed(id: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let PackAdminStoragePath: StoragePath
	
	// Counter for all the Packs ever minted
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver { 
		
		// Unique ID across all packs
		access(all)
		let id: UInt64
		
		// ID used to identify the kind of pack it is
		access(all)
		let packTemplateID: UInt64
		
		init(packTemplateID: UInt64) { 
			MFLPack.totalSupply = MFLPack.totalSupply + 1 as UInt64
			self.id = MFLPack.totalSupply
			self.packTemplateID = packTemplateID
			emit Minted(id: self.id, packTemplateID: packTemplateID, from: self.owner?.address)
		}
		
		// Get all supported views for this NFT
		access(all)
		view fun getViews(): [Type] { 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.ExternalURL>(), Type<MFLViews.PackDataViewV1>()]
		}
		
		// Resolve a specific view
		access(all)
		fun resolveView(_ view: Type): AnyStruct? { 
			let packTemplateData = MFLPackTemplate.getPackTemplate(id: self.packTemplateID)!
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: packTemplateData.name, description: "MFL Pack #".concat(self.id.toString()), thumbnail: MetadataViews.HTTPFile(url: packTemplateData.imageUrl))
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					let royaltyReceiverCap = getAccount(MFLAdmin.royaltyAddress()).capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)
					royalties.append(MetadataViews.Royalty(receiver: royaltyReceiverCap!, cut: 0.05, description: "Creator Royalty"))
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionDisplay>():
					let socials ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/playMFL"), "discord": MetadataViews.ExternalURL("https://discord.gg/pEDTR4wSPr"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/playmfl"), "medium": MetadataViews.ExternalURL("https://medium.com/playmfl")}
					return MetadataViews.NFTCollectionDisplay(name: "MFL Pack Collection", description: "MFL is a unique Web3 Football (Soccer) Management game & ecosystem where you\u{2019}ll be able to own and develop your football players as well as build a club from the ground up. As in real football, you\u{2019}ll be able to : Be a recruiter (Scout, find, and trade players\u{2026}), be an agent (Find the best clubs for your players, negotiate contracts with club owners\u{2026}), be a club owner (Develop your club, recruit players, compete in leagues and tournaments\u{2026}) and be a coach (Train and develop your players, play matches, and define your match tactics...). This collection allows you to collect Packs.", externalURL: MetadataViews.ExternalURL("https://playmfl.com"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/logos/mfl_logo_black_square_small.svg"), mediaType: "image/svg+xml"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/players/banner_1900_X_600.png"), mediaType: "image/png"), socials: socials)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MFLPack.CollectionStoragePath, publicPath: MFLPack.CollectionPublicPath, publicCollection: Type<&MFLPack.Collection>(), publicLinkedType: Type<&MFLPack.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MFLPack.createEmptyCollection(nftType: Type<@MFLPack.Collection>())
						})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://playmfl.com")
				case Type<MFLViews.PackDataViewV1>():
					return MFLViews.PackDataViewV1(id: self.id, packTemplate: packTemplateData)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection} { 
			return <-create Collection()
		}
	}
	
	// Main Collection to manage all the Packs NFT
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection { 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
		
		init() { 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} { 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection} { 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}) { 
			let token <- token as! @MFLPack.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64] { 
			return self.ownedNFTs.keys
		}
		
		// Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? { 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? { 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &MFLPack.NFT
			return packNFT as &{ViewResolver.Resolver}
		}
		
		// Called by any account that want to open a specific pack
		access(all)
		fun openPack(id: UInt64) { 
			let pack <- self.withdraw(withdrawID: id) as! @MFLPack.NFT
			let packTemplate = MFLPackTemplate.getPackTemplate(id: pack.packTemplateID)!
			
			// Check if packTemplate is openable or if the owner must wait before opening the pack
			assert(packTemplate.isOpenable, message: "PackTemplate is not openable")
			
			// Emit an event which will be processed by the backend to distribute the content of the pack
			emit Opened(id: pack.id, from: (self.owner!).address)
			destroy pack
		}
		
		access(all)
		view fun getSupportedNFTTypes(): {Type: Bool} { 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool { 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection} { 
			return <-create Collection()
		}
	}
	
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} { 
		return <-create Collection()
	}
	
	access(all)
	resource PackAdmin { 
		access(all)
		let name: String
		
		init() { 
			self.name = "PackAdminClaim"
		}
		
		access(PackAdminAction)
		fun batchMintPack(packTemplateID: UInt64, nbToMint: UInt32): @Collection { 
			MFLPackTemplate.increasePackTemplateCurrentSupply(id: packTemplateID, nbToMint: nbToMint)
			let newCollection <- create Collection()
			var i: UInt32 = 0
			while i < nbToMint{ 
				let pack <- create NFT(packTemplateID: packTemplateID)
				newCollection.deposit(token: <-pack)
				i = i + 1 as UInt32
			}
			return <-newCollection
		}
		
		access(PackAdminAction)
		fun createPackAdmin(): @PackAdmin { 
			return <-create PackAdmin()
		}
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/MFLPackCollection
		self.CollectionPublicPath = /public/MFLPackCollection
		self.PackAdminStoragePath = /storage/MFLPackAdmin
		
		// Initialize contract fields
		self.totalSupply = 0
		
		// Create a Collection and save it to storage
		self.account.storage.save<@MFLPack.Collection>(<-MFLPack.createEmptyCollection(nftType: Type<@MFLPack.Collection>()), to: MFLPack.CollectionStoragePath)
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&MFLPack.Collection>(MFLPack.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: MFLPack.CollectionPublicPath)
		
		// Create PackAdmin resource and save it to storage
		self.account.storage.save(<-create PackAdmin(), to: self.PackAdminStoragePath)
		emit ContractInitialized()
	}
}