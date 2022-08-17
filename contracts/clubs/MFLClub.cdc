import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MetadataViews from "../_libs/MetadataViews.cdc"
import MFLViews from "../views/MFLViews.cdc"

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows an admin to mint clubs (NFTs) and squads. Club and Squad have metadata
  that can be updated by an admin.
**/

pub contract MFLClub: NonFungibleToken {

    // Global Events
    pub event ContractInitialized()

    // Clubs Events
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event ClubMinted(id: UInt64)
    pub event ClubStatusUpdated(id: UInt64)
    pub event ClubMetadataUpdated(id: UInt64)
    pub event ClubSquadsIDsUpdated(id: UInt64)
    pub event ClubDestroyed(id: UInt64)
    pub event ClubFounded(id: UInt64, from: Address?, name: String, description: String, license: FoundationLicense?)
    pub event ClubInfosUpdated(id: UInt64, infos: {String: String})

    // Squads Events
    pub event SquadMinted(id: UInt64)
    pub event SquadUpdated(id: UInt64)
    pub event SquadDestroyed(id: UInt64)
    pub event SquadAddedToClub(clubID: UInt64, squadID: UInt64)

    // Named Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ClubAdminStoragePath: StoragePath
    pub let SquadAdminStoragePath: StoragePath

    // The total number of Clubs that have been minted
    pub var totalSupply: UInt64

    // All clubs datas are stored in this dictionary
    access(self) let clubsDatas: {UInt64: ClubData}

    // The total number of Squads that have been minted
    pub var squadsTotalSupply: UInt64

    // Squads resources can be stored in this dictionary if needed
    access(self) let squads: @{UInt64: Squad}

    // All squads data are stored in this dictionary
    access(self) let squadsDatas: {UInt64: SquadData}

    pub struct SquadData {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let type: String
        access(contract) var metadata: {String: AnyStruct}

        init(id: UInt64, clubID: UInt64, type: String, metadata: {String: AnyStruct}) {
            self.id = id
            self.clubID = clubID
            self.type = type
            self.metadata = metadata //? { competitionsMemberships: {leagueID: 1, division: 5}
        }

        access(contract) fun setMetadata(metadata: {String: AnyStruct}) {
            self.metadata = metadata
        }
    }

    pub resource Squad {
        pub let id: UInt64
        pub let clubID: UInt64
        pub let type: String
        access(self) var metadata: {String: AnyStruct}

        init(id: UInt64, clubID: UInt64, type: String, metadata: {String: AnyStruct}) {
            self.id = id
            self.clubID = clubID
            self.type = type
            self.metadata = metadata
            MFLClub.squadsTotalSupply = MFLClub.squadsTotalSupply + (1 as UInt64)

            // Set squad data
            MFLClub.squadsDatas[id] = MFLClub.SquadData(
                id: id,
                clubID:clubID,
                type: type,
                metadata: metadata
            ) 
            emit SquadMinted(id: self.id)
        }

        destroy() {
            // ? remove data in central ledger ? (not the case for player for ex.)
            emit SquadDestroyed(id: self.id)
        }
    }

    pub enum Status: UInt8 {
        pub case NOT_FOUNDED
        pub case FOUNDED
        pub case PENDING_VALIDATION
    }

    // Data stored in clubsDatas. Updatable by an admin
    pub struct ClubData {
        pub let id: UInt64
        access(contract) var status: Status
        access(contract) var squadsIDs: [UInt64]
        access(contract) var metadata: {String: AnyStruct}

        init(id: UInt64, status: Status, squadsIDs: [UInt64], metadata: {String: AnyStruct}) {
            self.id = id
            self.status = status
            self.squadsIDs = squadsIDs
            self.metadata = metadata
        }

        access(contract) fun setStatus(status: Status) {
            self.status = status
        }

        access(contract) fun setSquadsIDs(squadsIDs: [UInt64]) {
            self.squadsIDs = squadsIDs
        }

        access(contract) fun setMetadata(metadata: {String: AnyStruct}) {
            self.metadata = metadata
        }
    }

    pub struct FoundationLicense {
        pub let serialNumber: UInt64
        pub let city: String?
        pub let country: String?
        pub let season: UInt32
        pub let image: MetadataViews.IPFSFile

        init(serialNumber: UInt64, city: String?, country: String?, season: UInt32, image: MetadataViews.IPFSFile) {
            self.serialNumber = serialNumber
            self.city = city
            self.country = country
            self.season = season
            self.image = image
        }
    }

    // The resource that represents the Club NFT
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let foundationLicense: FoundationLicense?
        access(self) var squads: @{UInt64: Squad}
        access(self) var metadata: {String: AnyStruct} // ? Is this really needed (if yes admin function to update NFT metadata) ? can we just add new key to metadata central ledger ?

        init(
            id: UInt64,
            foundationLicense: FoundationLicense?,
            squads: @[Squad],
            nftMetadata: {String: AnyStruct},
            metadata: {String: AnyStruct}
        ) {
            self.id = id
            self.foundationLicense = foundationLicense
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
                status: Status.NOT_FOUNDED,
                squadsIDs: squadsIDs,
                metadata: metadata
            )
            emit ClubMinted(id: self.id)
        }

        // Get all supported views for this NFT
        pub fun getViews(): [Type] {
            //TODO add views for nft-catalogue
            return [
                Type<MetadataViews.Display>(),
                Type<MFLViews.ClubDataViewV1>(),
                Type<MFLViews.SquadDataViewV1>()
            ]
        }

        // Resolve a specific view
        pub fun resolveView(_ view: Type): AnyStruct? {
            let clubData = MFLClub.getClubData(id: self.id)!
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: clubData.metadata["name"] as! String? ?? "",
                        description: clubData.metadata["description"] as! String? ?? "",
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://d11e2517uhbeau.cloudfront.net/clubs/".concat(self.id.toString()).concat("/thumbnail.png") //TODO change path staging / prod
                        ),
                    )
                case Type<MFLViews.ClubDataViewV1>():
                    return MFLViews.ClubDataViewV1(
                        id: clubData.id,
                        foundationLicense: self.foundationLicense,
                        status: clubData.status,
                        squadsIDs: clubData.squadsIDs,
                        metadata: clubData.metadata
                    )
                case Type<MFLViews.SquadDataViewV1>():
                    let squadsDatasView: [MFLViews.SquadDataViewV1] = []
                    for id in clubData.squadsIDs {
                        if let squadData = MFLClub.getSquadData(id: id) {
                            squadsDatasView.append(MFLViews.SquadDataViewV1(
                                id: squadData.id,
                                clubID: squadData.clubID,
                                type: squadData.type,
                                metadata: squadData.metadata
                            ))
                        }
                    }
                    return squadsDatasView
            }
            return nil
        }

        access(contract) fun addSquad(squad: @Squad) {
            let oldSquad <- self.squads.insert(key: squad.id, <-squad)
            destroy oldSquad
        }

        destroy() {
            destroy self.squads
            emit ClubDestroyed(id: self.id)
        }
    }

     pub resource interface Owner {
        pub fun foundClub(id: UInt64, name: String, description: String)
        pub fun setClubInfos(id: UInt64, infos: {String: String})
    }

    // A collection of Club NFTs owned by an account
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, Owner {

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

        access(contract) fun borrowClubRef(id: UInt64): &MFLClub.NFT? {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return ref as! &MFLClub.NFT?
        }

        // TODO contract borrowSquadRef ?

        pub fun foundClub(id: UInt64, name: String, description: String) {
            let clubRef = self.borrowClubRef(id: id) ?? panic("Club not found")
            let clubData = MFLClub.getClubData(id: id) ?? panic("Data not found")
            if clubData.status == Status.FOUNDED {
                panic("Club already founded")
            }
            if clubData.status == Status.PENDING_VALIDATION {
                panic("Waiting for validation")
            }
            let updatedMetadata = clubData.metadata
            updatedMetadata.insert(key: "name", name)
            updatedMetadata.insert(key: "description", description)
            updatedMetadata.insert(key: "city", clubRef.foundationLicense?.city ?? "")
            updatedMetadata.insert(key: "country", clubRef.foundationLicense?.country ?? "")
            updatedMetadata.insert(key: "foundationDate", getCurrentBlock().timestamp)
            MFLClub.clubsDatas[id]!.setMetadata(metadata: updatedMetadata)
            MFLClub.clubsDatas[id]!.setStatus(status: Status.PENDING_VALIDATION)
            emit ClubFounded(
                id: id,
                from: self.owner?.address,
                name: name,
                description: description,
                license:clubRef.foundationLicense
            )
        }

        // ? restrict this method nb of times ? multi sign ? no because it s just an event and we can check this on the backend ?
        pub fun setClubInfos(id: UInt64, infos: {String: String}) {
            pre {
                self.getIDs().contains(id) == true : "Club not found"
            }
            let clubData = MFLClub.getClubData(id: id) ?? panic("Data not found")
            if clubData.status == Status.NOT_FOUNDED {
                panic("Club not founded")
            }
            if clubData.status == Status.PENDING_VALIDATION {
                panic("Waiting for validation")
            }
            // TODO update club infos like foundClub method here on check backend ?
            emit ClubInfosUpdated(id: id, infos: infos)
        }

        //? addSquad here (mutli sig)? Can be public because Squad minting is restricted to admin ?
        pub fun addSquad(clubID: UInt64, squad: @Squad) {
            // Add Squad id to central metadata
            let squadID = squad.id
            let clubData = MFLClub.getClubData(id: clubID) ?? panic("Data not found")
            var squadsIDs = clubData.squadsIDs
            assert(!squadsIDs.contains(squadID), message: "Squad id already exists")
            squadsIDs.append(squadID)
            MFLClub.clubsDatas[clubID]!.setSquadsIDs(squadsIDs: squadsIDs)

            // Add Squad resource to Club NFT
            let clubRef = self.borrowClubRef(id: clubID) ?? panic("Club not found")
            clubRef.addSquad(squad: <-squad)
            emit SquadAddedToClub(clubID: clubID, squadID: squadID)
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
            foundationLicense: FoundationLicense,
            squads: @[Squad],
            nftMetadata: {String: AnyStruct},
            metadata: {String: AnyStruct},
        ): @MFLClub.NFT
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
            foundationLicense: FoundationLicense,
            squads: @[Squad],
            nftMetadata: {String: AnyStruct},
            metadata: {String: AnyStruct}
        ): @MFLClub.NFT {
            pre {
                MFLClub.getClubData(id: id) == nil: "Club already exists"
            }
            let club <- create MFLClub.NFT(
                id: id,
                foundationLicense: foundationLicense,
                squads: <- squads,
                nftMetadata: nftMetadata,
                metadata: metadata
            )
            return <- club
        }

        pub fun updateClubStatus(id: UInt64, status: Status) {
            pre {
                MFLClub.getClubData(id: id) != nil : "Data not found"
            }
            MFLClub.clubsDatas[id]!.setStatus(status: status)
            emit ClubStatusUpdated(id: id)
        }

        pub fun updateClubMetadata(id: UInt64, metadata: {String: AnyStruct}) {
            pre {
                MFLClub.getClubData(id: id) != nil  : "Data not found"
            }
            MFLClub.clubsDatas[id]!.setMetadata(metadata: metadata)
            emit ClubMetadataUpdated(id: id)
        }

        //TODO update status / metadata all in one ??
        pub fun updateClubSquadsIDs(id: UInt64, squadsIDs: [UInt64]) {
            pre {
                MFLClub.getClubData(id: id) != nil : "Data not found"
            }
            MFLClub.clubsDatas[id]!.setSquadsIDs(squadsIDs: squadsIDs)
            emit ClubSquadsIDsUpdated(id: id) // TODO different event to diff with update metadata
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
            metadata: {String: AnyStruct}
        ): @Squad
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
            metadata: {String: AnyStruct}
        ): @Squad {
            pre {
                MFLClub.getSquadData(id: id) == nil : "Squad already exists"
            }
            let squad <- create Squad(
                id: id,
                clubID: clubID,
                type: type,
                metadata: nftMetadata
            )
            return <- squad
        }

        pub fun createSquadAdmin(): @SquadAdmin {
            return <- create SquadAdmin()
        } 
    }

    init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/MFLClubCollection
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
        self.squads <- {}
        self.squadsDatas = {}

        emit ContractInitialized()
    }

}