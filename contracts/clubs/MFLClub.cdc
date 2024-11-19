import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import ViewResolver from "../_libs/ViewResolver.cdc"
import FungibleToken from "../_libs/FungibleToken.cdc"
import MetadataViews from "../_libs/MetadataViews.cdc"
import MFLAdmin from "../core/MFLAdmin.cdc"

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows an admin to mint clubs (NFTs) and squads. Clubs and squads have metadata that can be updated by an admin.
**/

access(all)
contract MFLClub: NonFungibleToken {
	// Entitlements
	access(all)
	entitlement ClubAdminAction

	access(all)
	entitlement SquadAdminAction

	access(all)
	entitlement ClubAction

	// Global Events
	access(all)
	event ContractInitialized()

	access(all)
	event Withdraw(id: UInt64, from: Address?)

	access(all)
	event Deposit(id: UInt64, to: Address?)

	access(all)
	event ClubMinted(id: UInt64)

	access(all)
	event ClubStatusUpdated(id: UInt64, status: UInt8)

	access(all)
	event ClubMetadataUpdated(id: UInt64)

	access(all)
	event ClubSquadsIDsUpdated(id: UInt64, squadsIDs: [UInt64])

	access(all)
	event ClubInfoUpdateRequested(id: UInt64, info: {String: String})

	access(all)
	event ClubFounded(
		id: UInt64,
		from: Address?,
		name: String,
		description: String,
		foundationDate: UFix64,
		foundationLicenseSerialNumber: UInt64?,
		foundationLicenseCity: String?,
		foundationLicenseCountry: String?,
		foundationLicenseSeason: UInt32?
	)

	// Squads Events
	access(all)
	event SquadMinted(id: UInt64)

	access(all)
	event SquadMetadataUpdated(id: UInt64)

	access(all)
	event SquadCompetitionMembershipAdded(id: UInt64, competitionID: UInt64)

	access(all)
	event SquadCompetitionMembershipUpdated(id: UInt64, competitionID: UInt64)

	access(all)
	event SquadCompetitionMembershipRemoved(id: UInt64, competitionID: UInt64)

	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath

	access(all)
	let CollectionPrivatePath: PrivatePath

	access(all)
	let CollectionPublicPath: PublicPath

	access(all)
	let ClubAdminStoragePath: StoragePath

	access(all)
	let SquadAdminStoragePath: StoragePath

	// The total number of clubs that have been minted
	access(all)
	var totalSupply: UInt64

	// All clubs datas are stored in this dictionary
	access(self)
	let clubsDatas: {UInt64: ClubData}

	// The total number of squads that have been minted
	access(all)
	var squadsTotalSupply: UInt64

	// All squads data are stored in this dictionary
	access(self)
	let squadsDatas: {UInt64: SquadData}

	access(all)
	enum SquadStatus: UInt8 {
		access(all)
		case ACTIVE
	}

	access(all)
	struct SquadData {
		access(all)
		let id: UInt64

		access(all)
		let clubID: UInt64

		access(all)
		let type: String

		access(self)
		var status: SquadStatus

		access(self)
		var metadata: {String: AnyStruct}

		access(self)
		var competitionsMemberships: {UInt64: AnyStruct} // {competitionID: AnyStruct}


		init(id: UInt64, clubID: UInt64, type: String, metadata: {String: AnyStruct}, competitionsMemberships: {UInt64: AnyStruct}) {
			self.id = id
			self.clubID = clubID
			self.type = type
			self.status = SquadStatus.ACTIVE
			self.metadata = metadata
			self.competitionsMemberships = {}
			for competitionID in competitionsMemberships.keys {
				self.addCompetitionMembership(competitionID: competitionID, competitionMembershipData: competitionsMemberships[competitionID])
			}
		}

		// Getter for metadata
		access(all)
		view fun getMetadata(): {String: AnyStruct} {
			return self.metadata
		}

		// Setter for metadata
		access(contract)
		fun setMetadata(metadata: {String: AnyStruct}) {
			self.metadata = metadata
			emit SquadMetadataUpdated(id: self.id)
		}

		// Getter for competitionsMemberships
		access(all)
		view fun getCompetitionsMemberships(): {UInt64: AnyStruct} {
			return self.competitionsMemberships
		}

		// Add competitionMembership
		access(contract)
		fun addCompetitionMembership(competitionID: UInt64, competitionMembershipData: AnyStruct) {
			self.competitionsMemberships.insert(key: competitionID, competitionMembershipData)
			emit SquadCompetitionMembershipAdded(id: self.id, competitionID: competitionID)
		}

		// Update competitionMembership
		access(contract)
		fun updateCompetitionMembership(competitionID: UInt64, competitionMembershipData: AnyStruct) {
			pre {
				self.competitionsMemberships[competitionID] != nil:
					"Competition membership not found"
			}
			self.competitionsMemberships[competitionID] = competitionMembershipData
			emit SquadCompetitionMembershipUpdated(id: self.id, competitionID: competitionID)
		}

		// Remove competitionMembership
		access(contract)
		fun removeCompetitionMembership(competitionID: UInt64) {
			self.competitionsMemberships.remove(key: competitionID)
			emit SquadCompetitionMembershipRemoved(id: self.id, competitionID: competitionID)
		}

		// Getter for status
		access(all)
		view fun getStatus(): SquadStatus {
			return self.status
		}
	}

	access(all)
	resource Squad {
		access(all)
		let id: UInt64

		access(all)
		let clubID: UInt64

		access(all)
		let type: String

		access(self)
		var metadata: {String: AnyStruct}

		init(
			id: UInt64,
			clubID: UInt64,
			type: String,
			nftMetadata: {String: AnyStruct},
			metadata: {String: AnyStruct},
			competitionsMemberships: {UInt64: AnyStruct}
		) {
			pre {
				MFLClub.getSquadData(id: id) == nil:
					"Squad already exists"
			}
			self.id = id
			self.clubID = clubID
			self.type = type
			self.metadata = nftMetadata
			MFLClub.squadsTotalSupply = MFLClub.squadsTotalSupply + 1 as UInt64

			// Set squad data
			MFLClub.squadsDatas[id] = MFLClub.SquadData(id: id, clubID: clubID, type: type, metadata: metadata, competitionsMemberships: competitionsMemberships)
			emit SquadMinted(id: self.id)
		}
	}

	access(all)
	enum ClubStatus: UInt8 {
		access(all)
		case NOT_FOUNDED

		access(all)
		case PENDING_VALIDATION

		access(all)
		case FOUNDED
	}

	// Data stored in clubsDatas. Updatable by an admin
	access(all)
	struct ClubData {
		access(all)
		let id: UInt64

		access(self)
		var status: ClubStatus

		access(self)
		var squadsIDs: [UInt64]

		access(self)
		var metadata: {String: AnyStruct}

		init(id: UInt64, status: ClubStatus, squadsIDs: [UInt64], metadata: {String: AnyStruct}) {
			self.id = id
			self.status = status
			self.squadsIDs = squadsIDs
			self.metadata = metadata
		}

		// Getter for status
		access(all)
		view fun getStatus(): ClubStatus {
			return self.status
		}

		// Setter for status
		access(contract)
		fun setStatus(status: ClubStatus) {
			self.status = status
			emit ClubStatusUpdated(id: self.id, status: self.status.rawValue)
		}

		// Getter for squadsIDs
		access(all)
		view fun getSquadIDs(): [UInt64] {
			return self.squadsIDs
		}

		// Setter for squadsIDs
		access(contract)
		fun setSquadsIDs(squadsIDs: [UInt64]) {
			self.squadsIDs = squadsIDs
			emit ClubSquadsIDsUpdated(id: self.id, squadsIDs: self.squadsIDs)
		}

		// Getter for metadata
		access(all)
		view fun getMetadata(): {String: AnyStruct} {
			return self.metadata
		}

		// Setter for metadata
		access(contract)
		fun setMetadata(metadata: {String: AnyStruct}) {
			self.metadata = metadata
			emit ClubMetadataUpdated(id: self.id)
		}
	}

	// The resource that represents the Club NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
		access(all)
		let id: UInt64

		access(self)
		let squads: @{UInt64: Squad}

		access(self)
		let metadata: {String: AnyStruct}

		init(id: UInt64, squads: @[Squad], nftMetadata: {String: AnyStruct}, metadata: {String: AnyStruct}) {
			pre {
				MFLClub.getClubData(id: id) == nil:
					"Club already exists"
			}
			self.id = id
			self.squads <-{}
			self.metadata = nftMetadata
			let squadsIDs: [UInt64] = []
			while squads.length > 0 {
				squadsIDs.append(squads[0].id)
				let oldSquad <- self.squads[squads[0].id] <- squads.remove(at: 0)
				destroy oldSquad
			}
			destroy squads
			MFLClub.totalSupply = MFLClub.totalSupply + 1 as UInt64

			// Set club data
			MFLClub.clubsDatas[id] = ClubData(id: self.id, status: ClubStatus.NOT_FOUNDED, squadsIDs: squadsIDs, metadata: metadata)
			emit ClubMinted(id: self.id)
		}

		// Get all supported views for this NFT
		access(all)
		view fun getViews(): [Type] {
			return [
				Type<MetadataViews.Display>(),
				Type<MetadataViews.Royalties>(),
				Type<MetadataViews.NFTCollectionDisplay>(),
				Type<MetadataViews.NFTCollectionData>(),
				Type<MetadataViews.ExternalURL>(),
				Type<MetadataViews.Traits>(),
				Type<MetadataViews.Serial>()
			]
		}

		// Resolve a specific view
		access(all)
		fun resolveView(_ view: Type): AnyStruct? {
			let clubData = MFLClub.getClubData(id: self.id)!
			switch view {
				case Type<MetadataViews.Display>():
					if clubData.getStatus() == ClubStatus.NOT_FOUNDED {
						return MetadataViews.Display(
							name: "Club License #".concat(clubData.id.toString()),
							description: "MFL Club License #".concat(clubData.id.toString()),
							thumbnail: MetadataViews.HTTPFile(
								url: "https://d13e14gtps4iwl.cloudfront.net/clubs/".concat(clubData.id.toString()).concat("/licenses/foundation.png")
							)
						)
					} else {
						let clubMetadata = clubData.getMetadata()
						let division: UInt32? = clubMetadata["division"] as! UInt32?
						let clubDescription = clubMetadata["description"] as! String? ?? ""
						return MetadataViews.Display(
							name: clubMetadata["name"] as! String? ?? "",
							description: "Before purchasing this MFL Club, make sure to check the club's in-game profile for the latest information: https://app.playmfl.com/clubs/"
								.concat(clubData.id.toString())
								.concat(clubDescription != "" ? "\n\n---\n\n".concat(clubDescription) : ""),
							thumbnail: MetadataViews.HTTPFile(
								url: "https://d13e14gtps4iwl.cloudfront.net/u/clubs/"
									.concat(clubData.id.toString())
									.concat("/logo.png")
									.concat(division != nil ? "?v=".concat(division!.toString()) : "")
							)
						)
					}
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					let royaltyReceiverCap = getAccount(MFLAdmin.royaltyAddress()).capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)
					royalties.append(MetadataViews.Royalty(receiver: royaltyReceiverCap!, cut: 0.05, description: "Creator Royalty"))
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionDisplay>():
					 return MFLClub.resolveContractView(resourceType: Type<@MFLClub.NFT>(), viewType: Type<MetadataViews.NFTCollectionDisplay>())
				case Type<MetadataViews.NFTCollectionData>():
					 return MFLClub.resolveContractView(resourceType: Type<@MFLClub.NFT>(), viewType: Type<MetadataViews.NFTCollectionData>())
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://playmfl.com")
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []

					// TODO must be fixed correctly in the data rather than here.
					// foundationLicenseCity and foundationLicenseCountry should always be of type String? in the metadata
					let clubMetadata = clubData.getMetadata()
					var city: String? = nil
					var country: String? = nil
					if clubData.getStatus() == ClubStatus.NOT_FOUNDED {
						city = clubMetadata["foundationLicenseCity"] as! String?
						country = clubMetadata["foundationLicenseCountry"] as! String?
					} else {
						city = clubMetadata["foundationLicenseCity"] as! String?? ?? nil
						country = clubMetadata["foundationLicenseCountry"] as! String?? ?? nil
					}
					var division: UInt32? = clubMetadata["division"] as! UInt32?

					traits.append(MetadataViews.Trait(name: "city", value: city, displayType: "String", rarity: nil))
					traits.append(MetadataViews.Trait(name: "country", value: country, displayType: "String", rarity: nil))

					if division != nil {
						traits.append(MetadataViews.Trait(name: "division", value: division, displayType: "Number", rarity: nil))
					} else {
						let squadsIDs = clubData.getSquadIDs()
						if squadsIDs.length > 0 {
							let firstSquadID = squadsIDs[0]
							if let squadData = MFLClub.getSquadData(id: firstSquadID) {
								if let globalLeagueMembership = squadData.getCompetitionsMemberships()[1] {
									if let globalLeagueMembershipDataOptional = globalLeagueMembership as? {String: AnyStruct}? {
										if let globalLeagueMembershipData = globalLeagueMembershipDataOptional {
											traits.append(MetadataViews.Trait(
												name: "division",
												value: globalLeagueMembershipData["division"] as! UInt32?,
												displayType: "Number",
												rarity: nil
											))
										}
									}
								}
							}
						}
					}

					return MetadataViews.Traits(traits)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(clubData.id)
			}
			return nil
		}

		// Getter for metadata
		access(contract)
		view fun getMetadata(): {String: AnyStruct} {
			return self.metadata
		}

		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection} {
			return <-create Collection()
		}
	}

	// A collection of Club NFTs owned by an account
	access(all)
	resource Collection: NonFungibleToken.Collection, ViewResolver.ResolverCollection {

		// Dictionary of NFT conforming tokens
		access(all)
		var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// Withdraws multiple Clubs and returns them as a Collection
		access(NonFungibleToken.Withdraw)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection} {
			var batchCollection <- create Collection()

			// Iterate through the ids and withdraw them from the Collection
			for id in ids {
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}

		// Takes a NFT and adds it to the collections dictionary and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}) {
			let token <- token as! @MFLClub.NFT
			let id: UInt64 = token.id

			// Add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

			destroy oldToken
		}

		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		access(all)
		view fun getLength(): Int {
			return self.ownedNFTs.length
		}

		// Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
		}

		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
				return nft as &{ViewResolver.Resolver}
            }
            return nil
		}

		access(self)
		view fun borrowClubRef(id: UInt64): &MFLClub.NFT? {
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &MFLClub.NFT?
		}

		access(ClubAction)
		fun foundClub(id: UInt64, name: String, description: String) {
			let clubRef = self.borrowClubRef(id: id) ?? panic("Club not found")
			let clubData = MFLClub.getClubData(id: id) ?? panic("Club data not found")
			assert(clubData.getStatus() == ClubStatus.NOT_FOUNDED, message: "Club already founded")
			let updatedMetadata = clubData.getMetadata()
			let foundationDate = getCurrentBlock().timestamp
			let foundationLicenseSerialNumber = clubRef.getMetadata()["foundationLicenseSerialNumber"] as! UInt64?
			let foundationLicenseCity = clubRef.getMetadata()["foundationLicenseCity"] as! String?
			let foundationLicenseCountry = clubRef.getMetadata()["foundationLicenseCountry"] as! String?
			let foundationLicenseSeason = clubRef.getMetadata()["foundationLicenseSeason"] as! UInt32?
			let foundationLicenseImage = clubRef.getMetadata()["foundationLicenseImage"] as! MetadataViews.IPFSFile?
			updatedMetadata.insert(key: "name", name)
			updatedMetadata.insert(key: "description", description)
			updatedMetadata.insert(key: "foundationDate", foundationDate)
			updatedMetadata.insert(key: "foundationLicenseSerialNumber", foundationLicenseSerialNumber)
			updatedMetadata.insert(key: "foundationLicenseCity", foundationLicenseCity)
			updatedMetadata.insert(key: "foundationLicenseCountry", foundationLicenseCountry)
			updatedMetadata.insert(key: "foundationLicenseSeason", foundationLicenseSeason)
			updatedMetadata.insert(key: "foundationLicenseImage", foundationLicenseImage)
			(MFLClub.clubsDatas[id]!).setMetadata(metadata: updatedMetadata)
			(MFLClub.clubsDatas[id]!).setStatus(status: ClubStatus.PENDING_VALIDATION)
			emit ClubFounded(
				id: id,
				from: self.owner?.address,
				name: name,
				description: description,
				foundationDate: foundationDate,
				foundationLicenseSerialNumber: foundationLicenseSerialNumber,
				foundationLicenseCity: foundationLicenseCity,
				foundationLicenseCountry: foundationLicenseCountry,
				foundationLicenseSeason: foundationLicenseSeason
			)
		}

		access(ClubAction)
		fun requestClubInfoUpdate(id: UInt64, info: {String: String}) {
			pre {
				self.getIDs().contains(id) == true:
					"Club not found"
			}
			let clubData = MFLClub.getClubData(id: id) ?? panic("Club data not found")
			assert(clubData.getStatus() == ClubStatus.FOUNDED, message: "Club not founded")
			emit ClubInfoUpdateRequested(id: id, info: info)
		}

		access(all)
		view fun getSupportedNFTTypes(): {Type: Bool} {
			let supportedTypes: {Type: Bool} = {}
			supportedTypes[Type<@MFLClub.NFT>()] = true
			return supportedTypes
		}

		access(all)
		view fun isSupportedNFTType(type: Type): Bool {
			return type == Type<@MFLClub.NFT>()
		}

		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection} {
			return <-create Collection()
		}

		access(contract)
		view fun emitNFTUpdated(_ id: UInt64) {
			MFLClub.emitNFTUpdated((&self.ownedNFTs[id] as auth(NonFungibleToken.Update) &{NonFungibleToken.NFT}?)!)
		}

		init() {
			self.ownedNFTs <-{}
		}
	}

	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
		return <-create Collection()
	}

	// Get data for a specific club ID
	access(all)
	view fun getClubData(id: UInt64): ClubData? {
		return self.clubsDatas[id]
	}

	// Get data for a specific squad ID
	access(all)
	view fun getSquadData(id: UInt64): SquadData? {
		return self.squadsDatas[id]
	}

	access(all)
	view fun getContractViews(resourceType: Type?): [Type] {
		return [
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>()
		]
	}

	access(all)
	fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
		switch viewType {
			case Type<MetadataViews.NFTCollectionData>():
				let collectionData = MetadataViews.NFTCollectionData(
					storagePath: self.CollectionStoragePath,
					publicPath: self.CollectionPublicPath,
					publicCollection: Type<&MFLClub.Collection>(),
					publicLinkedType: Type<&MFLClub.Collection>(),
					createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
						return <-MFLClub.createEmptyCollection(nftType: Type<@MFLClub.NFT>())
					})
				)
				return collectionData
			case Type<MetadataViews.NFTCollectionDisplay>():
				return MetadataViews.NFTCollectionDisplay(
					name: "MFL Club Collection",
					description: "Build your own football club, make strategic decisions, and live the thrill of real competition. Join a universe where the stakes–and your rivals–are real.",
					externalURL: MetadataViews.ExternalURL("https://playmfl.com"),
					squareImage: MetadataViews.Media(
						file: MetadataViews.HTTPFile(url: "https://app.playmfl.com/img/mflAvatar.png"),
						mediaType: "image/png"
					),
					bannerImage: MetadataViews.Media(
						file: MetadataViews.HTTPFile(url: "https://app.playmfl.com/img/thumbnail.png"),
						mediaType: "image/png"
					),
					socials: {
						"twitter": MetadataViews.ExternalURL("https://twitter.com/playMFL"),
						"discord": MetadataViews.ExternalURL("https://discord.gg/pEDTR4wSPr"),
						"linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/playmfl"),
						"medium": MetadataViews.ExternalURL("https://medium.com/playmfl")
					}
				)
		}
		return nil
	}

	// Deprecated: Only here for backward compatibility.
	access(all)
	resource interface ClubAdminClaim {}

	access(all)
	resource ClubAdmin: ClubAdminClaim {
		access(all)
		let name: String

		init() {
			self.name = "ClubAdminClaim"
		}

		access(ClubAdminAction)
		fun mintClub(id: UInt64, squads: @[Squad], nftMetadata: {String: AnyStruct}, metadata: {String: AnyStruct}): @MFLClub.NFT {
			let club <- create MFLClub.NFT(id: id, squads: <-squads, nftMetadata: nftMetadata, metadata: metadata)
			return <-club
		}

		access(ClubAdminAction)
		fun updateClubStatus(id: UInt64, status: ClubStatus) {
			pre {
				MFLClub.getClubData(id: id) != nil:
					"Club data not found"
			}
			(MFLClub.clubsDatas[id]!).setStatus(status: status)
		}

		access(ClubAdminAction)
		fun updateClubMetadata(id: UInt64, metadata: {String: AnyStruct}, collectionRefOptional: &MFLClub.Collection?) {
			pre {
				MFLClub.getClubData(id: id) != nil:
					"Club data not found"
			}
			(MFLClub.clubsDatas[id]!).setMetadata(metadata: metadata)
			if let collectionRef = collectionRefOptional {
				collectionRef.emitNFTUpdated(id)
			}
		}

		access(ClubAdminAction)
		fun updateClubSquadsIDs(id: UInt64, squadsIDs: [UInt64]) {
			pre {
				MFLClub.getClubData(id: id) != nil:
					"Club data not found"
			}
			(MFLClub.clubsDatas[id]!).setSquadsIDs(squadsIDs: squadsIDs)
		}

		access(ClubAdminAction)
		fun createClubAdmin(): @ClubAdmin {
			return <-create ClubAdmin()
		}
	}

	// Deprecated: Only here for backward compatibility.
	access(all)
	resource interface SquadAdminClaim {}

	access(all)
	resource SquadAdmin: SquadAdminClaim {
		access(all)
		let name: String

		init() {
			self.name = "SquadAdminClaim"
		}

		access(SquadAdminAction)
		fun mintSquad(
			id: UInt64,
			clubID: UInt64,
			type: String,
			nftMetadata: {String: AnyStruct},
			metadata: {String: AnyStruct},
			competitionsMemberships: {UInt64: AnyStruct}
		): @Squad {
			let squad <- create Squad(
				id: id,
				clubID: clubID,
				type: type,
				nftMetadata: nftMetadata,
				metadata: metadata,
				competitionsMemberships: competitionsMemberships
			)
			return <-squad
		}

		access(SquadAdminAction)
		fun updateSquadMetadata(id: UInt64, metadata: {String: AnyStruct}) {
			pre {
				MFLClub.getSquadData(id: id) != nil:
					"Squad data not found"
			}
			(MFLClub.squadsDatas[id]!).setMetadata(metadata: metadata)
		}

		access(SquadAdminAction)
		fun addSquadCompetitionMembership(id: UInt64, competitionID: UInt64, competitionMembershipData: AnyStruct) {
			pre {
				MFLClub.getSquadData(id: id) != nil:
					"Squad data not found"
			}
			(MFLClub.squadsDatas[id]!).addCompetitionMembership(competitionID: competitionID, competitionMembershipData: competitionMembershipData)
		}

		access(SquadAdminAction)
		fun updateSquadCompetitionMembership(id: UInt64, competitionID: UInt64, competitionMembershipData: AnyStruct) {
			pre {
				MFLClub.getSquadData(id: id) != nil:
					"Squad data not found"
			}
			(MFLClub.squadsDatas[id]!).updateCompetitionMembership(competitionID: competitionID, competitionMembershipData: competitionMembershipData)
		}

		access(SquadAdminAction)
		fun removeSquadCompetitionMembership(id: UInt64, competitionID: UInt64) {
			pre {
				MFLClub.getSquadData(id: id) != nil:
					"Squad data not found"
			}
			(MFLClub.squadsDatas[id]!).removeCompetitionMembership(competitionID: competitionID)
		}

		access(SquadAdminAction)
		fun createSquadAdmin(): @SquadAdmin {
			return <-create SquadAdmin()
		}
	}

	init() {
		// Set our named paths
		self.CollectionStoragePath = /storage/MFLClubCollection
		self.CollectionPrivatePath = /private/MFLClubCollection
		self.CollectionPublicPath = /public/MFLClubCollection
		self.ClubAdminStoragePath = /storage/MFLClubAdmin
		self.SquadAdminStoragePath = /storage/MFLSquadAdmin

		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&MFLClub.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)

		// Create a ClubAdmin resource and save it to storage
		self.account.storage.save(<-create ClubAdmin(), to: self.ClubAdminStoragePath)
		// Create SquadAdmin resource and save it to storage
		self.account.storage.save(<-create SquadAdmin(), to: self.SquadAdminStoragePath)

		// Initialize contract fields
		self.totalSupply = 0
		self.squadsTotalSupply = 0
		self.clubsDatas = {}
		self.squadsDatas = {}
		emit ContractInitialized()
	}
}
