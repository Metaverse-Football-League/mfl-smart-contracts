import FungibleToken from "../_libs/FungibleToken.cdc"
import FUSD from "../_libs/FUSD.cdc"
import MFLPack from "../packs/MFLPack.cdc"
import MFLPackTemplate from "../packs/MFLPackTemplate.cdc"

pub contract MFLDrop {

    // Events
    pub event ContractInitialized()
    pub event Created(id: UInt64)
    pub event StatusUpdated(status: UInt8)
    pub event SetWhitelistedAddresses(addresses: {Address: UInt32} )

    // Named Paths
    pub let DropAdminStoragePath: StoragePath

    pub enum Status: UInt8 {
        pub case closed
        pub case opened_whitelist
        pub case opened_all
    }

    pub var nextDropID: UInt64
    pub var ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>?
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

        access(contract) fun mint(address: Address, nbToMint: UInt32, senderVault: @FungibleToken.Vault, recipientCap: Capability<&{MFLPack.CollectionPublic}>) {
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

            let newCollection <- MFLPack.mint(packTemplateID: self.packTemplateID, nbToMint: nbToMint, address: address)
            // let castSenderVault <- senderVault as! @FUSD.Vault
            // TODO Test if flow are sent instead of FUSD
            let ownerVaultRef = MFLDrop.ownerVault?.borrow() ?? panic("Could not borrow reference to owner vault")
            ownerVaultRef!.deposit(from: <- senderVault)
            self.minters[address] = (self.minters[address] ?? (0 as UInt32)) + nbToMint

            recipientCap.borrow()!.batchDeposit(tokens : <- newCollection)
        }

        access(contract) fun setStatus(status: Status) {
            self.status = status
            emit StatusUpdated(status: status.rawValue)
        }

        access(contract) fun setWhitelistedAddresses(addresses: {Address: UInt32}) {
            for address in addresses.keys {
                if addresses[address]! > self.maxTokensPerAddress {
                    panic("Nb must be smaller or equal to maxTokensPerAddress")
                }
                self.whitelistedAddresses[address] = addresses[address]
            }
            emit SetWhitelistedAddresses(addresses: addresses)
        }

        access(contract) fun setMaxTokensPerAddress(maxTokensPerAddress: UInt32) {
            self.maxTokensPerAddress = maxTokensPerAddress
        }
    }

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

    pub fun getDropsIDs(): [UInt64] {
        return self.drops.keys
    }

    pub fun getDropsStatuses(): {UInt64: Status} {
        let dropsStatus: {UInt64: Status} = {}
        for id in self.getDropsIDs() {
            if let drop = self.getDropRef(id: id) {
                dropsStatus[id] = drop.status
            }
        }
        return dropsStatus
    }

    access(self) fun getDropRef(id: UInt64): &MFLDrop.Drop? {
        if self.drops[id] != nil {
            let ref = &self.drops[id] as auth &MFLDrop.Drop
            return ref
        } else {
            return nil
        }
    }

    pub fun purchase(
        dropID: UInt64,
        address: Address,
        nbToMint: UInt32,
        senderVault: @FungibleToken.Vault,
        recipientCap: Capability<&{MFLPack.CollectionPublic}>
    ) {
        pre {
            self.getDropsIDs().contains(dropID) : "Drop does not exist"
        }
        self.getDropRef(id: dropID)!.mint(address: address, nbToMint: nbToMint, senderVault: <-senderVault, recipientCap: recipientCap)
    }

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

        // Create DropAdmin
        self.account.save(<- create DropAdmin() , to: self.DropAdminStoragePath)
        
        emit ContractInitialized()
    }
}
