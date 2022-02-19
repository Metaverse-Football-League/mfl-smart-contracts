import FungibleToken from "../_libs/FungibleToken.cdc"
import NonFungibleToken from "../_libs/NonFungibleToken.cdc"
import MFLPack from "../packs/MFLPack.cdc"
import MFLPackTemplate from "../packs/MFLPackTemplate.cdc"

/**
  This contract allows MFL to create and manage drops. Basically, a drop can have different status 
  and will among other things define the price of a pack, the maximum number of packs per address,... . 
  Each drop must be linked to an existing packTemplate (see MFLPackTemplate contract for more info).
**/

pub contract MFLDrop {

    // Events
    pub event ContractInitialized()
    pub event Created(id: UInt64)
    pub event StatusUpdated(status: UInt8)
    pub event SetWhitelistedAddresses(addresses: {Address: UInt32} )

    // Named Paths
    pub let DropAdminStoragePath: StoragePath

    // Possible status of a drop
    pub enum Status: UInt8 {
        pub case closed
        pub case opened_whitelist
        pub case opened_all
    }

    pub var nextDropID: UInt64
    // The owner vault allows MFL to receveive payments from the purchase of the packs
    pub var ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>?
    // All drops  are stored in this dictionary
    access(self) let drops : @{UInt64: Drop}

    pub struct DropData {

        pub let id: UInt64
        pub let name: String
        pub let price: UFix64
        pub let status: UInt8
        pub let packTemplateID: UInt64
        pub let maxTokensPerAddress: UInt32
        pub let minters: {Address: UInt32}
        pub let whitelistedAddresses: {Address: UInt32}

        init(
            id: UInt64,
            name: String,
            price: UFix64,
            status: UInt8,
            packTemplateID: UInt64,
            maxTokensPerAddress: UInt32,
            minters: {Address: UInt32},
            whitelistedAddresses: {Address: UInt32}
        ) {
            self.id = id
            self.name = name
            self.price = price
            self.status = status
            self.packTemplateID = packTemplateID
            self.maxTokensPerAddress = maxTokensPerAddress
            self.minters = minters
            self.whitelistedAddresses = whitelistedAddresses
        }
    }

    pub resource Drop {

        access(contract) let id: UInt64
        access(contract) let name: String
        access(contract) let price: UFix64
        access(contract) var status: Status
        access(contract) let packTemplateID: UInt64

        // Maximum number of tokens a single address can mint
        access(contract) var maxTokensPerAddress: UInt32

        // Addresses that have minted one or more NFTs with the number of tokens they have minted
        access(contract) let minters: {Address: UInt32}

        // Whitelisted addresses with the corresponding number of tokens they are allowed to mint
        access(contract) let whitelistedAddresses: {Address: UInt32}

        init(name: String, price: UFix64, packTemplateID: UInt64, maxTokensPerAddress: UInt32) {
            self.id = MFLDrop.nextDropID
            MFLDrop.nextDropID = MFLDrop.nextDropID + (1 as UInt64)
            self.name = name
            self.price = price
            self.status = Status.closed
            self.packTemplateID = packTemplateID
            self.maxTokensPerAddress = maxTokensPerAddress
            self.minters = {}
            self.whitelistedAddresses = {}
        }

        // Called by purchase fct below and ensures that an account has the right to buy packs
        access(contract) fun mint(address: Address, nbToMint: UInt32, senderVault: @FungibleToken.Vault, recipientCap: Capability<&{NonFungibleToken.CollectionPublic}>) {
            pre {
                address == recipientCap.borrow()!.owner!.address : "Address is not valid" // Check if address is the right one (to ensure fair randmoness logic in MFLPackTemplate)
                self.status != Status.closed : "Drop is closed"
                nbToMint > (0 as UInt32) : "Nb to mint must be greater than 0"
                ((self.minters[address] ?? (0 as UInt32)) + nbToMint) <= self.maxTokensPerAddress : "Max tokens per address exceeded"
                self.status == Status.opened_all ||
                    (self.status == Status.opened_whitelist && ((self.whitelistedAddresses[address] ?? (0 as UInt32)) > (0 as UInt32))): "Not whitelisted"
                self.status == Status.opened_all ||
                    (self.status == Status.opened_whitelist && (( (self.minters[address] ?? (0 as UInt32)) + nbToMint) <= self.whitelistedAddresses[address]!) ): "Max tokens exceeded for whitelist"
                senderVault.balance >= (UFix64(nbToMint) * self.price) : "Not enough balance"
            }

            let tokens <- MFLPack.mint(packTemplateID: self.packTemplateID, nbToMint: nbToMint, address: address)
            let ownerVaultRef = MFLDrop.ownerVault?.borrow() ?? panic("Could not borrow reference to owner vault")
            ownerVaultRef!.deposit(from: <- senderVault)
            self.minters[address] = (self.minters[address] ?? (0 as UInt32)) + nbToMint
            let keys = tokens.getIDs()
            for key in keys {
                recipientCap.borrow()!.deposit(token: <-tokens.withdraw(withdrawID: key))
            }
            destroy tokens
        }

        // Update the drop status
        access(contract) fun setStatus(status: Status) {
            self.status = status
            emit StatusUpdated(status: status.rawValue)
        }

        // Update the drop whitelistedAddresses dictionary
        access(contract) fun setWhitelistedAddresses(addresses: {Address: UInt32}) {
            for address in addresses.keys {
                if addresses[address]! > self.maxTokensPerAddress {
                    panic("Nb must be smaller or equal to maxTokensPerAddress")
                }
                self.whitelistedAddresses[address] = addresses[address]
            }
            emit SetWhitelistedAddresses(addresses: addresses)
        }

        // Update the drop maxTokensPerAddress
        access(contract) fun setMaxTokensPerAddress(maxTokensPerAddress: UInt32) {
            self.maxTokensPerAddress = maxTokensPerAddress
        }
    }

    // Get a data reprensation of a specific drop
    pub fun getDrop(id: UInt64): DropData? {
        if let drop = self.getDropRef(id: id) {
            return DropData(
                id: drop.id,
                name: drop.name,
                price: drop.price,
                status: drop.status.rawValue,
                packTemplateID: drop.packTemplateID,
                maxTokensPerAddress: drop.maxTokensPerAddress,
                minters: drop.minters,
                whitelistedAddresses: drop.whitelistedAddresses
            )
        }
        return nil
    }

    // Get a data reprensation of all drops
    pub fun getDrops(): [DropData] {
        var dropsData: [DropData] = []
        for id in self.getDropsIDs() {
            if let drop = self.getDropRef(id: id) {
                dropsData.append(DropData(
                    id: drop.id,
                    name: drop.name,
                    price: drop.price,
                    status: drop.status.rawValue,
                    packTemplateID: drop.packTemplateID,
                    maxTokensPerAddress: drop.maxTokensPerAddress,
                    minters: drop.minters,
                    whitelistedAddresses: drop.whitelistedAddresses
                ))
            }
        }
        return dropsData
    }

    // Get all drop IDs
    pub fun getDropsIDs(): [UInt64] {
        return self.drops.keys
    }

    // Get all drop statuses
    pub fun getDropsStatuses(): {UInt64: Status} {
        let dropsStatus: {UInt64: Status} = {}
        for id in self.getDropsIDs() {
            if let drop = self.getDropRef(id: id) {
                dropsStatus[id] = drop.status
            }
        }
        return dropsStatus
    }

    // Get a specif drop ref (in particular for calling admin methods)
    access(self) fun getDropRef(id: UInt64): &MFLDrop.Drop? {
        if self.drops[id] != nil {
            let ref = &self.drops[id] as auth &MFLDrop.Drop
            return ref
        } else {
            return nil
        }
    }

    // This is the entrypoint of the contract for accounts that wish to purchase packs
    pub fun purchase(
        dropID: UInt64,
        address: Address,
        nbToMint: UInt32,
        senderVault: @FungibleToken.Vault,
        recipientCap: Capability<&{NonFungibleToken.CollectionPublic}>
    ) {
        pre {
            self.getDropsIDs().contains(dropID) : "Drop does not exist"
        }
        self.getDropRef(id: dropID)!.mint(address: address, nbToMint: nbToMint, senderVault: <-senderVault, recipientCap: recipientCap)
    }

    // This interface allows any account that has a private capability to a DropAdminClaim to call the methods below
    pub resource interface DropAdminClaim {
        pub let name: String
        pub fun createDrop(name: String, price: UFix64, packTemplateID: UInt64, maxTokensPerAddress: UInt32)
        pub fun setOwnerVault(vault: Capability<&AnyResource{FungibleToken.Receiver}>)
        pub fun setStatus(id: UInt64, status: Status)
        pub fun setWhitelistedAddresses(id: UInt64, addresses: {Address: UInt32})
        pub fun setMaxTokensPerAddress(id: UInt64, maxTokensPerAddress: UInt32)
    }

    pub resource DropAdmin: DropAdminClaim {
        pub let name: String

        init() {
            self.name = "DropAdminClaim"
        }

        pub fun createDrop(name: String, price: UFix64, packTemplateID: UInt64, maxTokensPerAddress: UInt32) {
            pre {
                MFLPackTemplate.getPackTemplatesIDs().contains(packTemplateID) : "Pack template id does not exist"
            }

            let newDrop <- create Drop(
                name: name,
                price: price,
                packTemplateID: packTemplateID,
                maxTokensPerAddress: maxTokensPerAddress,
            )
            emit Created(id: newDrop.id)
            let oldPackTemplate <- MFLDrop.drops[newDrop.id] <- newDrop
            destroy oldPackTemplate
        }

        pub fun setOwnerVault(vault: Capability<&AnyResource{FungibleToken.Receiver}>) {
            MFLDrop.ownerVault = vault
        }

        pub fun setStatus(id: UInt64, status: Status) {
            MFLDrop.getDropRef(id: id)!.setStatus(status: status)
        }

        pub fun setWhitelistedAddresses(id: UInt64, addresses: {Address: UInt32}) {
            MFLDrop.getDropRef(id: id)!.setWhitelistedAddresses(addresses: addresses)
        }

        pub fun setMaxTokensPerAddress(id: UInt64, maxTokensPerAddress: UInt32) {
            MFLDrop.getDropRef(id: id)!.setMaxTokensPerAddress(maxTokensPerAddress: maxTokensPerAddress)
        }

        pub fun createDropAdmin(): @DropAdmin {
            return <- create DropAdmin()
        }
    }

    init() {
        // Set our named paths
        self.DropAdminStoragePath = /storage/MFLDropAdmin

        // Initialize contract fields
        self.nextDropID = 1
        self.drops <- {}
        self.ownerVault = nil

        // Create a DropAdmin resource and save it to storage
        self.account.save(<- create DropAdmin() , to: self.DropAdminStoragePath)
        
        emit ContractInitialized()
    }
}
