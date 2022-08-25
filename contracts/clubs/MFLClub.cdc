import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MetadataViews from "../_libs/MetadataViews.cdc"

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows an admin to mint clubs (NFTs) and squads. Clubs and squads have metadata that can be updated by an admin.
**/

pub contract MFLClub: NonFungibleToken {

    // Global Events
    pub event ContractInitialized()

    // Clubs Events
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event ClubMinted(id: UInt64)
    pub event ClubStatusUpdated(id: UInt64, status: UInt8)
    pub event ClubMetadataUpdated(id: UInt64)
    pub event ClubSquadsIDsUpdated(id: UInt64, squadsIDs: [UInt64])
    pub event ClubDestroyed(id: UInt64)
    pub event ClubInfoUpdateRequested(id: UInt64, info: {String: String})
    pub event ClubFounded(
        id: UInt64,
        from: Address?,
        name: String,
        description: String,
        foundationDate: UFix64,
        foundationLicenseSerialNumber: UInt64?,
        foundationLicenseCity: String?,
        foundationLicenseCountry: String?,
        foundationLicenseSeason: UInt32?,
        foundationLicenseImage: MetadataViews.IPFSFile?
    )

    // Squads Events
    pub event SquadMinted(id: UInt64)
    pub event SquadDestroyed(id: UInt64)
    pub event SquadMetadataUpdated(id: UInt64)
    pub event SquadCompetitionMembershipAdded(id: UInt64, competitionID: UInt64)
    pub event SquadCompetitionMembershipRemoved(id: UInt64, competitionID: UInt64)

    // Named Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPrivatePath: PrivatePath
    pub let CollectionPublicPath: PublicPath
    pub let ClubAdminStoragePath: StoragePath
    pub let SquadAdminStoragePath: StoragePath

    // The total number of clubs that have been minted
    pub var totalSupply: UInt64

    // All clubs datas are stored in this dictionary
    access(self) let clubsDatas: {UInt64: ClubData}

    // The total number of squads that have been minted
    pub var squadsTotalSupply: UInt64

    // All squads data are stored in this dictionary
    access(self) let squadsDatas: {UInt64: SquadData}

    pub enum SquadStatus: UInt8 {
        pub case ACTIVE
    }

    pub struct SquadData {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let type: String
        access(self) var status: SquadStatus
        access(self) var metadata: {String: AnyStruct}
        access(self) var competitionsMemberships: {UInt64: AnyStruct} // {competitionID: AnyStruct}

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
        pub fun getMetadata(): {String: AnyStruct} {
            return self.metadata
        }

        // Setter for metadata
        access(contract) fun setMetadata(metadata: {String: AnyStruct}) {
            self.metadata = metadata
            emit SquadMetadataUpdated(id: self.id)
        }

        // Getter for competitionsMemberships
         pub fun getCompetitionsMemberships(): {UInt64: AnyStruct} {
            return self.competitionsMemberships
        }

        // Add competitionMembership
        access(contract) fun addCompetitionMembership(competitionID: UInt64, competitionMembershipData: AnyStruct) {
            self.competitionsMemberships.insert(key: competitionID, competitionMembershipData)
            emit SquadCompetitionMembershipAdded(id: self.id, competitionID: competitionID)
        }

        // Remove competitionMembership
        access(contract) fun removeCompetitionMembership(competitionID: UInt64) {
            self.competitionsMemberships.remove(key: competitionID)
            emit SquadCompetitionMembershipRemoved(id: self.id, competitionID: competitionID)
        }

        // Getter for status
         pub fun getStatus(): SquadStatus {
            return self.status
        }
    }

    pub resource Squad {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let type: String
        access(self) var metadata: {String: AnyStruct}

        init(
            id: UInt64,
            clubID: UInt64,
            type: String,
            nftMetadata: {String: AnyStruct},
            metadata: {String: AnyStruct},
            competitionsMemberships: {UInt64: AnyStruct}
         ) {
            pre {
                MFLClub.getSquadData(id: id) == nil : "Squad already exists"
            }
            self.id = id
            self.clubID = clubID
            self.type = type
            self.metadata = nftMetadata
            MFLClub.squadsTotalSupply = MFLClub.squadsTotalSupply + (1 as UInt64)

            // Set squad data
            MFLClub.squadsDatas[id] = MFLClub.SquadData(
                id: id,
                clubID:clubID,
                type: type,
                metadata: metadata,
                competitionsMemberships: competitionsMemberships,
            ) 
            emit SquadMinted(id: self.id)
        }

        destroy() {
            emit SquadDestroyed(id: self.id)
        }
    }

    pub enum ClubStatus: UInt8 {
        pub case NOT_FOUNDED
        pub case PENDING_VALIDATION
        pub case FOUNDED
    }

    // Data stored in clubsDatas. Updatable by an admin
    pub struct ClubData {
        pub let id: UInt64
        access(self) var status: ClubStatus
        access(self) var squadsIDs: [UInt64]
        access(self) var metadata: {String: AnyStruct}

        init(id: UInt64, status: ClubStatus, squadsIDs: [UInt64], metadata: {String: AnyStruct}) {
            self.id = id
            self.status = status
            self.squadsIDs = squadsIDs
            self.metadata = metadata
        }

        // Getter for status
        pub fun getStatus(): ClubStatus {
            return self.status
        }

        // Setter for status
        access(contract) fun setStatus(status: ClubStatus) {
            self.status = status
            emit ClubStatusUpdated(id: self.id, status: self.status.rawValue)
        }

        // Getter for squadsIDs
        pub fun getSquadIDs(): [UInt64] {
            return self.squadsIDs
        }

        // Setter for squadsIDs
        access(contract) fun setSquadsIDs(squadsIDs: [UInt64]) {
            self.squadsIDs = squadsIDs
            emit ClubSquadsIDsUpdated(id: self.id, squadsIDs: self.squadsIDs)
        }

        // Getter for metadata
        pub fun getMetadata(): {String: AnyStruct} {
            return self.metadata
        }

        // Setter to update all metadata
        access(contract) fun setMetadata(metadata: {String: AnyStruct}) {
            self.metadata = metadata
            emit ClubMetadataUpdated(id: self.id)
        }
    }

    // The resource that represents the Club NFT
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        access(self) let squads: @{UInt64: Squad}
        access(self) let metadata: {String: AnyStruct}

        init(
            id: UInt64,
            squads: @[Squad],
            nftMetadata: {String: AnyStruct},
            metadata: {String: AnyStruct}
        ) {
            pre {
                MFLClub.getClubData(id: id) == nil: "Club already exists"
            }
            self.id = id
            self.squads <- {}
            self.metadata = nftMetadata
            let squadsIDs: [UInt64] = []
            var i = 0
            while i < squads.length {
                squadsIDs.append(squads[i].id)
                let oldSquad <- self.squads[squads[i].id] <- squads.remove(at: i)
                destroy oldSquad
                i = i + 1
            }
            destroy squads
            MFLClub.totalSupply = MFLClub.totalSupply + (1 as UInt64)

            // Set club data
            MFLClub.clubsDatas[id] = ClubData(
                id: self.id,
                status: ClubStatus.NOT_FOUNDED,
                squadsIDs: squadsIDs,
                metadata: metadata
            )
            emit ClubMinted(id: self.id)
        }

        // Get all supported views for this NFT
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.ExternalURL>()
            ]
        }

        // Resolve a specific view
        pub fun resolveView(_ view: Type): AnyStruct? {
            let clubData = MFLClub.getClubData(id: self.id)!
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: clubData.getMetadata()["name"] as! String? ?? "",
                        description: clubData.getMetadata()["description"] as! String? ?? "",
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://d11e2517uhbeau.cloudfront.net/clubs/".concat(self.id.toString()).concat("/thumbnail.png") //TODO change path staging / prod
                        ),
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([])
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let socials = {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/playMFL"),
                        "discord":  MetadataViews.ExternalURL("https://discord.gg/pEDTR4wSPr"),
                        "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/playmfl"),
                        "medium": MetadataViews.ExternalURL("https://medium.com/playmfl")
                    }
                    return MetadataViews.NFTCollectionDisplay(
                        name: "MFL Club Collection",
                        description: "MFL is a unique Web3 Football (Soccer) Management game & ecosystem where you’ll be able to own and develop your football players as well as build a club from the ground up. As in real football, you’ll be able to : Be a recruiter (Scout, find, and trade players…), be an agent (Find the best clubs for your players, negotiate contracts with club owners…), be a club owner (Develop your club, recruit players, compete in leagues and tournaments…) and be a coach (Train and develop your players, play matches, and define your match tactics...). This collection allows you to collect Clubs.",
                        externalURL: MetadataViews.ExternalURL("https://playmfl.com"),
                        squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/logos/mfl_logo_black_square_small.svg"), mediaType: "image/svg+xml"),
                        bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/players/banner_1900_X_600.png"), mediaType: "image/png"),
                        socials: socials
                    )
                 case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: MFLClub.CollectionStoragePath,
                        publicPath: MFLClub.CollectionPublicPath,
                        providerPath: MFLClub.CollectionPrivatePath,
                        publicCollection: Type<&MFLClub.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinked: Type<&MFLClub.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&MFLClub.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-MFLClub.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://playmfl.com")
            }
            return nil
        }

        // Getter for metadata
        access(contract) fun getMetadata(): {String: AnyStruct} {
            return self.metadata
        }

        destroy() {
            destroy self.squads
            emit ClubDestroyed(id: self.id)
        }
    }

    // A collection of Club NFTs owned by an account
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

        // Dictionary of NFT conforming tokens
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // Removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // Withdraws multiple Clubs and returns them as a Collection
        pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
            var batchCollection <- create Collection()

            // Iterate through the ids and withdraw them from the Collection
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }

            return <-batchCollection
        }


        // Takes a NFT and adds it to the collections dictionary and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @MFLClub.NFT

            let id: UInt64 = token.id

            // Add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // Returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let clubNFT = nft as! &MFLClub.NFT
            return clubNFT as &AnyResource{MetadataViews.Resolver}
        }

        access(self) fun borrowClubRef(id: UInt64): &MFLClub.NFT? {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return ref as! &MFLClub.NFT?
        }

        pub fun foundClub(id: UInt64, name: String, description: String) {
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
            MFLClub.clubsDatas[id]!.setMetadata(metadata: updatedMetadata)
            MFLClub.clubsDatas[id]!.setStatus(status: ClubStatus.PENDING_VALIDATION)
            emit ClubFounded(
                id: id,
                from: self.owner?.address,
                name: name,
                description: description,
                foundationDate: foundationDate,
                foundationLicenseSerialNumber: foundationLicenseSerialNumber,
                foundationLicenseCity: foundationLicenseCity,
                foundationLicenseCountry: foundationLicenseCountry,
                foundationLicenseSeason: foundationLicenseSeason,
                foundationLicenseImage: foundationLicenseImage,
            )
        }

        pub fun requestClubInfoUpdate(id: UInt64, info: {String: String}) {
            pre {
                self.getIDs().contains(id) == true : "Club not found"
            }
            let clubData = MFLClub.getClubData(id: id) ?? panic("Club data not found")
            assert(clubData.getStatus() == ClubStatus.FOUNDED, message: "Club not founded")
            emit ClubInfoUpdateRequested(id: id, info: info)
        }

        destroy() {
            destroy self.ownedNFTs
        }
        
        init() {
            self.ownedNFTs <- {}
        }
    }

    // Public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    // Get data for a specific club ID
    pub fun getClubData(id: UInt64): ClubData? {
        return self.clubsDatas[id]
    }

    // Get data for a specific squad ID
    pub fun getSquadData(id: UInt64): SquadData? {
        return self.squadsDatas[id]
    }

    // This interface allows any account that has a private capability to a ClubAdminClaim to call the methods below
    pub resource interface ClubAdminClaim {
        pub let name: String
        pub fun mintClub(
            id: UInt64,
            squads: @[Squad],
            nftMetadata: {String: AnyStruct},
            metadata: {String: AnyStruct},
        ): @MFLClub.NFT
        pub fun updateClubStatus(id: UInt64, status: ClubStatus)
        pub fun updateClubMetadata(id: UInt64, metadata: {String: AnyStruct})
        pub fun updateClubSquadsIDs(id: UInt64, squadsIDs: [UInt64])
    }

    pub resource ClubAdmin: ClubAdminClaim {
        pub let name: String

        init() {
            self.name = "ClubAdminClaim"
        }

        pub fun mintClub(
            id: UInt64,
            squads: @[Squad],
            nftMetadata: {String: AnyStruct},
            metadata: {String: AnyStruct}
        ): @MFLClub.NFT {
            let club <- create MFLClub.NFT(
                id: id,
                squads: <- squads,
                nftMetadata: nftMetadata,
                metadata: metadata
            )
            return <- club
        }

        pub fun updateClubStatus(id: UInt64, status: ClubStatus) {
            pre {
                MFLClub.getClubData(id: id) != nil : "Club data not found"
            }
            MFLClub.clubsDatas[id]!.setStatus(status: status)
        }

        pub fun updateClubMetadata(id: UInt64, metadata: {String: AnyStruct}) {
            pre {
                MFLClub.getClubData(id: id) != nil  : "Club data not found"
            }
            MFLClub.clubsDatas[id]!.setMetadata(metadata: metadata)
        }

        pub fun updateClubSquadsIDs(id: UInt64, squadsIDs: [UInt64]) {
            pre {
                MFLClub.getClubData(id: id) != nil : "Club data not found"
            }
            MFLClub.clubsDatas[id]!.setSquadsIDs(squadsIDs: squadsIDs)
        }

        pub fun createClubAdmin(): @ClubAdmin {
            return <- create ClubAdmin()
        }
    }

    // This interface allows any account that has a private capability to a SquadAdminClaim to call the methods below
    pub resource interface SquadAdminClaim {
        pub let name: String
        pub fun mintSquad(
            id: UInt64,
            clubID: UInt64,
            type: String,
            nftMetadata: {String: AnyStruct},
            metadata: {String: AnyStruct},
            competitionsMemberships: {UInt64: AnyStruct}
        ): @Squad
        pub fun updateSquadMetadata(id: UInt64, metadata: {String: AnyStruct})
        pub fun addSquadCompetitionMembership(id: UInt64, competitionID: UInt64, competitionMembershipData: AnyStruct)
        pub fun removeSquadCompetitionMembership(id: UInt64, competitionID: UInt64)
    }

    pub resource SquadAdmin: SquadAdminClaim {
        pub let name: String

        init() {
            self.name = "SquadAdminClaim"
        }

        pub fun mintSquad(
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
            return <- squad
        }

        pub fun updateSquadMetadata(id: UInt64, metadata: {String: AnyStruct}) {
            pre {
                MFLClub.getSquadData(id: id) != nil  : "Squad data not found"
            }
            MFLClub.getSquadData(id: id)!.setMetadata(metadata: metadata)
        }

        pub fun addSquadCompetitionMembership(id: UInt64, competitionID: UInt64, competitionMembershipData: AnyStruct) {
            pre {
                MFLClub.getSquadData(id: id) != nil  : "Squad data not found"
            }
            MFLClub.getSquadData(id: id)!.addCompetitionMembership(competitionID: competitionID, competitionMembershipData: competitionMembershipData)
        }

        pub fun removeSquadCompetitionMembership(id: UInt64, competitionID: UInt64) {
            pre {
                MFLClub.getSquadData(id: id) != nil  : "Squad data not found"
            }
            MFLClub.getSquadData(id: id)!.removeCompetitionMembership(competitionID: competitionID)
        }

        pub fun createSquadAdmin(): @SquadAdmin {
            return <- create SquadAdmin()
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
        self.account.save<@Collection>(<- create Collection(), to: self.CollectionStoragePath)
        // Create a public capability for the Collection
        self.account.link<&MFLClub.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        // Create a ClubAdmin resource and save it to storage
        self.account.save(<- create ClubAdmin() , to: self.ClubAdminStoragePath)
        // Create SquadAdmin resource and save it to storage
        self.account.save(<- create SquadAdmin() , to: self.SquadAdminStoragePath)

        // Initialize contract fields
        self.totalSupply = 0
        self.squadsTotalSupply = 0
        self.clubsDatas = {}
        self.squadsDatas = {}

        emit ContractInitialized()
    }
}