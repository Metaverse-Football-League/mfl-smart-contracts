import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MetadataViews from "../_libs/MetadataViews.cdc"

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

    // Named Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ClubAdminStoragePath: StoragePath

    // The total number of Clubs that have been minted
    pub var totalSupply: UInt64
    // All clubs datas are stored in this dictionary
    access(self) let clubsDatas: {UInt64: ClubData}

    // Data stored in clubsDatas. Updatable by an admin
    pub struct ClubData {
        pub let id: UInt64
        access(contract) let metadata: {String: AnyStruct}

        init(id: UInt64, metadata: {String: AnyStruct}) {
            self.id = id
            self.metadata = metadata
        }
    }

    pub enum Status: UInt8 {
        pub case NOT_FOUNDED
        pub case FOUNDED
    }

    pub struct OriginalLicense {
        pub let city: String
        pub let country: String
        pub let season: UInt32
        pub let image: {MetadataViews.File}

        init(city: String, country: String, season: UInt32, image: {MetadataViews.File}) {
            self.city = city
            self.country = country
            self.season = season
            self.image = image
        }
    }

    // The resource that represents the Club NFT
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let originalLicense: OriginalLicense
        pub var status: Status
        pub var creationDate: UFix64? // TODO Timestamp from backend or from contract

        init(id: UInt64, originalLicense: OriginalLicense) {
            self.id = id
            self.originalLicense = originalLicense
            self.status = Status.NOT_FOUNDED
            self.creationDate = nil
            MFLClub.totalSupply = MFLClub.totalSupply + (1 as UInt64)

            emit Minted(id: self.id)
        }

        // Get all supported views for this NFT
        pub fun getViews(): [Type] {
            return [Type<MetadataViews.Display>()]
        }

        // Resolve a specific view
        pub fun resolveView(_ view: Type): AnyStruct? {
            let clubData = MFLClub.getClubData(id: self.id)!
            //TODO we do not have image in ClubMetadata so we can't handle Display view
            // switch view {
            //     case Type<MetadataViews.Display>():
            //         return MetadataViews.Display(
            //             name: clubData.metadata["name"] as! String? ?? "",
            //             description: clubData.metadata["description"] as! String? ?? "",
            //             thumbnail: "",
            //         )
            // }
            return nil
        }

        destroy() {
            emit Destroyed(id: self.id)
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
        // pub fun mintClub(): @MFLClub.NFT
        // pub fun updateClubMetadata()// TODO how to update club metadata
    }

    pub resource ClubAdmin: ClubAdminClaim {
        pub let name: String

        init() {
            self.name = "ClubAdminClaim"
        }
    }

    init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/MFLClubCollection
        self.CollectionPublicPath = /public/MFLClubCollection
        self.ClubAdminStoragePath = /storage/MFLClubAdmin

        // Initialize contract fields
        self.totalSupply = 0
        self.clubsDatas = {}
    }

}