import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MetadataViews from "../_libs/MetadataViews.cdc"
import MFLViews from "../views/MFLViews.cdc"
import MFLAdmin from "../core/MFLAdmin.cdc"

pub contract MFLPlayer: NonFungibleToken {

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
    pub let PlayerAdminStoragePath: StoragePath


    // The total number of Players that have been minted
    pub var totalSupply: UInt64
    access(self) let playersDatas: {UInt64: PlayerData}

    // Data stored in playersdatas. Updatable by an admin
    pub struct PlayerData {
        pub let id: UInt64
        pub let metadata: {String: AnyStruct}
        pub let season: UInt32
        pub let ipfsURI: String

        init(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, ipfsURI: String) {
            self.id = id
            self.metadata = metadata
            self.season = season
            self.ipfsURI = ipfsURI
        }
    }

    // The resource that represents the Player NFT
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

        // The unique ID for the Player
        pub let id: UInt64
        pub let season: UInt32
        pub let ipfsURI: String

        init(id: UInt64, season: UInt32, ipfsURI: String) {
            self.id = id
            // Increment the totalSupply so that id it isn't used again
            MFLPlayer.totalSupply = MFLPlayer.totalSupply + (1 as UInt64)

            self.season = season
            self.ipfsURI = ipfsURI

            emit Minted(id: self.id)
        }

         pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MFLViews.PlayerDataViewV1>()
            ]
        }
        
        pub fun resolveView(_ view: Type): AnyStruct? {
            let playerData = MFLPlayer.getPlayerData(id: self.id)!
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: playerData.metadata["name"] as! String? ?? "",
                        description: "MFL Player #".concat(playerData.id.toString()),
                        thumbnail: MetadataViews.IPFSFile(cid: "", path: "") //TODO ipfs logic
                    )
                case Type<MFLViews.PlayerDataViewV1>():
                    return MFLViews.PlayerDataViewV1(
                       id: playerData.id,
                       metadata: playerData.metadata,
                       season: playerData.season,
                       ipfsURI: playerData.ipfsURI
                    )
            }
            return nil
        }

        pub fun getData(): PlayerData? {
            return MFLPlayer.getPlayerData(id: self.id);
        }

        destroy() {
            emit Destroyed(id: self.id)
        }
    }

    // This is the interface that users can cast their Players Collection as
    // to allow others to deposit Players into their Collection. It also allows for reading
    // the details of Players in the Collection.
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowPlayer(id: UInt64): &MFLPlayer.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Player reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // A collection of Player NFTs owned by an account
    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

        // Dictionary of NFT conforming tokens
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // Removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }


        // Withdraws multiple Players and returns them as a Collection
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
            let token <- token as! @MFLPlayer.NFT

            let id: UInt64 = token.id

            // Add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // batchDeposit takes a Collection object as an argument
        // and deposits each contained NFT into this Collection
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {

            // Get an array of the IDs to be deposited
            let keys = tokens.getIDs()

            // Iterate through the keys in the collection and deposit each one
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }

            // Destroy the empty Collection
            destroy tokens
        }


        // Returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // Gets a reference to an NFT in the collection as a Player,
        // exposing all of its fields
        pub fun borrowPlayer(id: UInt64): &MFLPlayer.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &MFLPlayer.NFT
            } else {
                return nil
            }
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
            let playerNFT = nft as! &MFLPlayer.NFT
            return playerNFT as &AnyResource{MetadataViews.Resolver}
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


    // Get a reference to a Player from an account's Collection, if available.
    // If an account does not have a MFLPlayer.Collection, panic.
    // If it has a Collection but does not contain the itemID, return nil.
    // If it has a Collection and that collection contains the itemID, return a reference to that.
    pub fun fetch(from: Address, itemID: UInt64): &MFLPlayer.NFT? {
        let collection = getAccount(from)
            .getCapability<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath)
            .borrow()
            ?? panic("Couldn't get collection")
        // We trust MFLPlayer.Collection.borrowPlayer to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowPlayer(id: itemID)
    }

    // Get data for a specific player ID
    pub fun getPlayerData(id: UInt64): PlayerData? {
        return self.playersDatas[id];
    }

    pub resource interface PlayerAdminClaim {
        pub let name: String
        pub fun mintPlayer(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, ipfsURI: String): @MFLPlayer.NFT
        pub fun updatePlayerMetadata(id: UInt64, metadata: {String: AnyStruct})
    }

    pub resource PlayerAdmin: PlayerAdminClaim {
        pub let name: String

        init() {
            self.name = "PlayerAdminClaim"
        }

        // Mint a new Player and returns it
        pub fun mintPlayer(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, ipfsURI: String): @MFLPlayer.NFT {
            pre {
                MFLPlayer.getPlayerData(id: id) == nil: "Player already exists"
            }

            let newPlayerNFT <- create MFLPlayer.NFT(
                id: id,
                season: season,
                ipfsURI: ipfsURI,
            )
            MFLPlayer.playersDatas[newPlayerNFT.id] = MFLPlayer.PlayerData(
                id: newPlayerNFT.id,
                metadata: metadata,
                season: season,
                ipfsURI: ipfsURI
            );
            return <- newPlayerNFT
        }

        // Update Player Metadata
        pub fun updatePlayerMetadata(id: UInt64, metadata: {String: AnyStruct}) {
            let playerData = MFLPlayer.playersDatas[id] ?? panic("Data not found")
            let updatedPlayerData = MFLPlayer.PlayerData(
                id: playerData.id,
                metadata: metadata,
                season: playerData.season,
                ipfsURI: playerData.ipfsURI
            )
            MFLPlayer.playersDatas[id] = updatedPlayerData

            emit Updated(id: id)
        }

        pub fun createPlayerAdmin(): @PlayerAdmin {
            return <- create PlayerAdmin()
        }
    }

    init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/MFLCollection
        self.CollectionPublicPath = /public/MFLCollection
        self.PlayerAdminStoragePath = /storage/MFLPlayerAdmin

        // Initialize contract fields
        self.totalSupply = 0
        self.playersDatas = {}

        // Put a new Collection in storage
        self.account.save<@Collection>(<- create Collection(), to: self.CollectionStoragePath)
        // Create a public capability for the Collection
        self.account.link<&{CollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)

        self.account.save(<- create PlayerAdmin() , to: self.PlayerAdminStoragePath)

        emit ContractInitialized()
    }
}

