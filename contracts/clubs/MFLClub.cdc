import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MetadataViews from "../_libs/MetadataViews.cdc"
import MFLViews from "../views/MFLViews.cdc"
import MFLSquad from "../squads/MFLSquad.cdc"

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows an admin to mint clubs (NFTs). A club has metadata
  that can be updated by an admin.
**/

pub contract MFLClub: NonFungibleToken {

    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64)
    pub event Updated(id: UInt64)
    pub event Destroyed(id: UInt64)
    pub event Founded(id: UInt64, name: String, description: String, license: FoundationLicense?)

    pub event InfosUpdated(id: UInt64, infos: {String: String})

    // Named Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ClubAdminStoragePath: StoragePath

    // The total number of Clubs that have been minted
    pub var totalSupply: UInt64
    // All clubs datas are stored in this dictionary
    access(self) let clubsDatas: {UInt64: ClubData}

    pub enum Status: UInt8 {
        pub case NOT_FOUNDED
        pub case FOUNDED
        pub case PENDING_VALIDATION
    }

    // Data stored in clubsDatas. Updatable by an admin
    pub struct ClubData {
        pub let id: UInt64
        pub let status: Status
        access(contract) var squadsIDs: [UInt64]
        access(contract) var metadata: {String: AnyStruct}

        init(id: UInt64, status: Status, squadsIDs: [UInt64], metadata: {String: AnyStruct}) {
            self.id = id
            self.status = status
            self.squadsIDs = squadsIDs
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
        access(self) let squads: @{UInt64: MFLSquad.Squad}
        access(self) let metadata: {String: AnyStruct}

        init(
            id: UInt64,
            foundationLicense: FoundationLicense?,
            squads: @[MFLSquad.Squad],
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

            emit Minted(id: self.id)
        }

        // Get all supported views for this NFT
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MFLViews.ClubDataViewV1>()
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
                // case Type<MFLViews.ClubDataViewV1>():
                //     return MFLViews.ClubDataViewV1(
                //         id: clubData.id,
                //         metadataMain: clubData.metadataMain,
                //         metadataTeams: clubData.metadataTeams
                //     )
            }
            return nil
        }

        destroy() {
            destroy self.squads
            emit Destroyed(id: self.id)
        }
    }

    // ? we can create interfaces to manage authorization . add them to resource Collection
   

    pub resource interface Manager {
        pub fun setClubInfos(id: UInt64, infos: {String: String})
    }

     pub resource interface Owner {
        pub fun foundClub(id: UInt64, name: String, description: String)
        pub fun setClubInfos(id: UInt64, infos: {String: String})
    }

    // A collection of Club NFTs owned by an account
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, Owner, Manager {

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

        pub fun foundClub(id: UInt64, name: String, description: String) {
            if let clubRef = self.borrowClubRef(id: id) {
                let clubData = MFLClub.clubsDatas[id] ?? panic("Data not found")
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
                MFLClub.clubsDatas[id] = MFLClub.ClubData(
                    id: clubData.id,
                    status: Status.PENDING_VALIDATION,
                    squadsIDs: clubData.squadsIDs,
                    metadata: updatedMetadata
                )
                emit Founded(
                    id: id,
                    name: name,
                    description: description,
                    license:clubRef.foundationLicense
                )
            }
        }

        //TODO one function set for name, desc, city, county ?
        pub fun setClubInfos(id: UInt64, infos: {String: String}) {
            if self.getIDs().contains(id) {
                let clubData = MFLClub.clubsDatas[id] ?? panic("Data not found")
                if clubData.status == Status.NOT_FOUNDED {
                    panic("Club not founded")
                }
                if clubData.status == Status.PENDING_VALIDATION {
                    panic("Waiting for validation")
                }
                emit InfosUpdated(id: id, infos: infos)
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
        
        init () {
            self.ownedNFTs <- {}
        }   
    }

    // Public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    // Get data for a specific club ID
    pub fun getClubData(id: UInt64): ClubData? {
        return self.clubsDatas[id];
    }

    // This interface allows any account that has a private capability to a ClubAdminClaim to call the methods below
    pub resource interface ClubAdminClaim {
        pub let name: String
        pub fun mintClub(
            id: UInt64,
            foundationLicense: FoundationLicense,
            squads: @[MFLSquad.Squad],
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
            squads: @[MFLSquad.Squad],
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

        pub fun updateClubMetadata(id: UInt64, metadata: {String: AnyStruct}) {
            let clubData = MFLClub.clubsDatas[id] ?? panic("Data not found")
            let updatedClubData = MFLClub.ClubData(
                id: clubData.id,
                status: clubData.status,
                squadsIDs: clubData.squadsIDs,
                metadata: metadata
            )
            MFLClub.clubsDatas[id] = updatedClubData
            emit Updated(id: id)
        }

        pub fun updateClubSquadsIDs(id: UInt64, squadsIDs: [UInt64]) {
            let clubData = MFLClub.clubsDatas[id] ?? panic("Data not found")
            let updatedClubData = MFLClub.ClubData(
                id: clubData.id,
                status: clubData.status,
                squadsIDs: squadsIDs,
                metadata: clubData.metadata
            )
            MFLClub.clubsDatas[id] = updatedClubData
            emit Updated(id: id)
        }

        pub fun createClubAdmin(): @ClubAdmin {
            return <- create ClubAdmin()
        }
    }

    init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/MFLClubCollection
        self.CollectionPublicPath = /public/MFLClubCollection
        self.ClubAdminStoragePath = /storage/MFLClubAdmin

        // Put a new Collection in storage
        self.account.save<@Collection>(<- create Collection(), to: self.CollectionStoragePath)
        // Create a public capability for the Collection
        self.account.link<&MFLClub.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        // Create a ClubAdmin resource and save it to storage
        self.account.save(<- create ClubAdmin() , to: self.ClubAdminStoragePath)

        // Initialize contract fields
        self.totalSupply = 0
        self.clubsDatas = {}

        emit ContractInitialized()
    }

}