import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import MFLViews from 0x8ebcbfd516b1da27
import MFLAdmin from 0x8ebcbfd516b1da27

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows an admin to mint players (NFTs). A player has metadata
  that can be updated by an admin.
**/

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
    // All players datas are stored in this dictionary
    access(self) let playersDatas: {UInt64: PlayerData}

    // Data stored in playersdatas. Updatable by an admin
    pub struct PlayerData {
        pub let id: UInt64
        access(contract) let metadata: {String: AnyStruct}
        pub let season: UInt32
        pub let image: {MetadataViews.File}

        init(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, image: {MetadataViews.File}) {
            self.id = id
            self.metadata = metadata
            self.season = season
            self.image = image
        }
    }

    // The resource that represents the Player NFT
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

        // The unique ID for the Player
        pub let id: UInt64
        pub let season: UInt32
        pub let image: {MetadataViews.File}

        init(id: UInt64, season: UInt32, image: {MetadataViews.File}) {
            self.id = id
            // Increment the totalSupply so that id it isn't used again
            MFLPlayer.totalSupply = MFLPlayer.totalSupply + (1 as UInt64)

            self.season = season
            self.image = image

            emit Minted(id: self.id)
        }

        // Get all supported views for this NFT
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MFLViews.PlayerDataViewV1>()
            ]
        }
        
        // Resolve a specific view
        pub fun resolveView(_ view: Type): AnyStruct? {
            let playerData = MFLPlayer.getPlayerData(id: self.id)!
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: playerData.metadata["name"] as! String? ?? "",
                        description: "MFL Player #".concat(playerData.id.toString()),
                        thumbnail: playerData.image
                    )
                case Type<MFLViews.PlayerDataViewV1>():
                    return MFLViews.PlayerDataViewV1(
                       id: playerData.id,
                       metadata: playerData.metadata,
                       season: playerData.season,
                       thumbnail: playerData.image
                    )
            }
            return nil
        }

        destroy() {
            emit Destroyed(id: self.id)
        }
    }

    // A collection of Player NFTs owned by an account
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

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

        // Returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
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

    // Get data for a specific player ID
    pub fun getPlayerData(id: UInt64): PlayerData? {
        return self.playersDatas[id];
    }

    // This interface allows any account that has a private capability to a PlayerAdminClaim to call the methods below
    pub resource interface PlayerAdminClaim {
        pub let name: String
        pub fun mintPlayer(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, image: {MetadataViews.File}): @MFLPlayer.NFT
        pub fun updatePlayerMetadata(id: UInt64, metadata: {String: AnyStruct})
    }

    pub resource PlayerAdmin: PlayerAdminClaim {
        pub let name: String

        init() {
            self.name = "PlayerAdminClaim"
        }

        // Mint a new Player and returns it
        pub fun mintPlayer(id: UInt64, metadata: {String: AnyStruct}, season: UInt32, image: {MetadataViews.File}): @MFLPlayer.NFT {
            pre {
                MFLPlayer.getPlayerData(id: id) == nil: "Player already exists"
            }

            let newPlayerNFT <- create MFLPlayer.NFT(
                id: id,
                season: season,
                image: image
            )
            MFLPlayer.playersDatas[newPlayerNFT.id] = MFLPlayer.PlayerData(
                id: newPlayerNFT.id,
                metadata: metadata,
                season: season,
                image: image
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
                image: playerData.image
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
        self.CollectionStoragePath = /storage/MFLPlayerCollection
        self.CollectionPublicPath = /public/MFLPlayerCollection
        self.PlayerAdminStoragePath = /storage/MFLPlayerAdmin

        // Initialize contract fields
        self.totalSupply = 0
        self.playersDatas = {}

        // Put a new Collection in storage
        self.account.save<@Collection>(<- create Collection(), to: self.CollectionStoragePath)
        // Create a public capability for the Collection
        self.account.link<&MFLPlayer.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        // Create a PlayerAdmin resource and save it to storage
        self.account.save(<- create PlayerAdmin() , to: self.PlayerAdminStoragePath)

        emit ContractInitialized()
    }
}

