import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MetadataViews from "../_libs/MetadataViews.cdc"
import MFLViews from "../views/MFLViews.cdc"
import MFLAdmin from "../core/MFLAdmin.cdc"

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
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Traits>(),
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
                        name: "MFL Player Collection",
                        description: "MFL is a unique Web3 Football (Soccer) Management game & ecosystem where you’ll be able to own and develop your football players as well as build a club from the ground up. As in real football, you’ll be able to : Be a recruiter (Scout, find, and trade players…), be an agent (Find the best clubs for your players, negotiate contracts with club owners…), be a club owner (Develop your club, recruit players, compete in leagues and tournaments…) and be a coach (Train and develop your players, play matches, and define your match tactics...). This collection allows you to collect Players.",
                        externalURL: MetadataViews.ExternalURL("https://playmfl.com"),
                        squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/logos/mfl_logo_black_square_small.svg"), mediaType: "image/svg+xml"),
                        bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/players/banner_1900_X_600.png"), mediaType: "image/png"),
                        socials: socials
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: MFLPlayer.CollectionStoragePath,
                        publicPath: MFLPlayer.CollectionPublicPath,
                        providerPath: /private/MFLPlayerCollection,
                        publicCollection: Type<&MFLPlayer.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinked: Type<&MFLPlayer.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&MFLPlayer.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-MFLPlayer.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://playmfl.com")
                case Type<MetadataViews.Traits>():
                    let traits: [MetadataViews.Trait] = []
                    traits.append(MetadataViews.Trait(name: "id", value: playerData.id, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "name", value: playerData.metadata["name"] as! String?, displayType: "String", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "nationalities", value: playerData.metadata["nationalities"] as! [String]?, displayType: nil, rarity: nil))
                    traits.append(MetadataViews.Trait(name: "positions", value: playerData.metadata["positions"] as! [String]?, displayType: nil, rarity: nil))
                    traits.append(MetadataViews.Trait(name: "preferredFoot", value: playerData.metadata["preferredFoot"] as! String?, displayType: "String", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "ageAtMint", value: playerData.metadata["ageAtMint"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "height", value: playerData.metadata["height"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "overall", value: playerData.metadata["overall"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "pace", value: playerData.metadata["pace"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "shooting", value: playerData.metadata["shooting"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "passing", value: playerData.metadata["passing"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "dribbling", value: playerData.metadata["dribbling"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "defense", value: playerData.metadata["defense"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "physical", value: playerData.metadata["physical"] as! UInt32?, displayType: "Number", rarity: nil))
                    traits.append(MetadataViews.Trait(name: "goalkeeping", value: playerData.metadata["goalkeeping"] as! UInt32?, displayType: "Number", rarity: nil))
                    return MetadataViews.Traits(traits)
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
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
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

