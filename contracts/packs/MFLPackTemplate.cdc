/**
  This contract allows MFL to create and manage packTemplates.
  A packTemplate is in a way the skeleton of a pack, where the max supply is defined,
  whether or not the packs linked to a packTemplate can be opened, and the startingIndex
  (which is one of the central elements of the pack content randomness logic).
**/

pub contract MFLPackTemplate {

    // Events
    pub event ContractInitialized()
    pub event Created(id: UInt64)
    pub event AllowToOpenPacks(id: UInt64)

    // Named Paths
    pub let PackTemplateAdminStoragePath: StoragePath

    pub var nextPackTemplateID :UInt64
    // All packTemplates  are stored in this dictionary
    access(self) let packTemplates : @{UInt64: PackTemplate}

    pub struct PackTemplateData {

        pub let id: UInt64
        pub let name: String
        pub let description: String?
        pub let maxSupply: UInt32
        pub let currentSupply: UInt32
        pub let startingIndex: UInt32
        pub let isOpenable: Bool
        pub let imageUrl: String

        init(
            id: UInt64,
            name: String,
            description: String?,
            maxSupply: UInt32,
            currentSupply: UInt32,
            startingIndex: UInt32,
            isOpenable: Bool,
            imageUrl: String
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.maxSupply = maxSupply
            self.currentSupply = currentSupply
            self.startingIndex = startingIndex
            self.isOpenable = isOpenable
            self.imageUrl = imageUrl
        }
    }

    pub resource PackTemplate {
        pub let id: UInt64
        access(contract) let name: String
        access(contract) let description: String?
        access(contract) let maxSupply: UInt32
        access(contract) var currentSupply: UInt32
        access(contract) var startingIndex: UInt32
        access(contract) var isOpenable: Bool
        access(contract) var imageUrl: String

        init(name: String, description: String?, maxSupply: UInt32, imageUrl: String) {
            self.id = MFLPackTemplate.nextPackTemplateID
            MFLPackTemplate.nextPackTemplateID = MFLPackTemplate.nextPackTemplateID + (1 as UInt64)
            self.name = name
            self.description = description
            self.maxSupply = maxSupply
            self.currentSupply = 0
            self.startingIndex = 0
            self.isOpenable = false
            self.imageUrl = imageUrl
        }

        // Enable accounts to open their packs
        access(contract) fun allowToOpenPacks() {
            self.isOpenable = true
        }

        // Only callable by a Pack mint fct (through getPackTemplateMintIndex). Update startingIndex and returns the mintIndex for the pack NFT
        access(contract) fun getMintIndex(nbToMint: UInt32, address: Address): UInt32 {
            pre {
                nbToMint <= self.maxSupply - self.currentSupply : "Not enough packs available"
            }

            let mintIndex = self.currentSupply
            self.currentSupply = self.currentSupply + nbToMint

            if(!self.isOpenable) {
                self.increaseStartingIndex(address: address)
            }

            return mintIndex
        }

        // Compute startingIndex for off-chain randomness logic of pack distribution
        access(self) fun increaseStartingIndex(address: Address) {
            pre {
                !self.isOpenable : "Starting index can't change once isOpenable is true"
            }

            var addrValue: UInt32 = 0
            let accountAddrBytes = address.toBytes()
            for accountAddrByte in accountAddrBytes {
                addrValue = addrValue + UInt32(accountAddrByte)
            }
            self.startingIndex = (self.startingIndex + addrValue) % self.maxSupply
        }
    }

    // Get all packTemplates IDs
    pub fun getPackTemplatesIDs(): [UInt64] {
        return self.packTemplates.keys
    }

    // Get a data reprensation of a specific packTemplate
    pub fun getPackTemplate(id: UInt64): PackTemplateData? {
        if let packTemplate = self.getPackTemplateRef(id: id) {
            return PackTemplateData(
                id: packTemplate.id,
                name: packTemplate.name,
                description : packTemplate.description,
                maxSupply : packTemplate.maxSupply,
                currentSupply : packTemplate.currentSupply,
                startingIndex : packTemplate.startingIndex,
                isOpenable: packTemplate.isOpenable,
                imageUrl: packTemplate.imageUrl
            )
        }
        return nil
    }

    // Get a data reprensation of all packTemplates
    pub fun getPackTemplates(): [PackTemplateData] {
        var packTemplatesData: [PackTemplateData] = []
        for id in self.getPackTemplatesIDs() {
            if let packTemplate = self.getPackTemplateRef(id: id) {
                packTemplatesData.append(PackTemplateData(
                    id: packTemplate.id,
                    name: packTemplate.name,
                    description : packTemplate.description,
                    maxSupply : packTemplate.maxSupply,
                    currentSupply : packTemplate.currentSupply,
                    startingIndex : packTemplate.startingIndex,
                    isOpenable: packTemplate.isOpenable,
                    imageUrl: packTemplate.imageUrl
                ))
            }
        }
        return packTemplatesData
    }

    // Get a specif packTemplate ref (in particular for calling admin methods)
    access(contract) fun getPackTemplateRef(id: UInt64): &MFLPackTemplate.PackTemplate? {
        if self.packTemplates[id] != nil {
            let ref = &self.packTemplates[id] as auth &MFLPackTemplate.PackTemplate
            return ref
        } else {
            return nil
        }
    }
    
    // Only callable by the Pack mint fct
    access(account) fun getPackTemplateMintIndex(id: UInt64, nbToMint: UInt32, address: Address): UInt32? {
        return self.getPackTemplateRef(id: id)?.getMintIndex(nbToMint: nbToMint, address: address)
    }
    
    // This interface allows any account that has a private capability to a PackTemplateAdminClaim to call the methods below
    pub resource interface PackTemplateAdminClaim {
        pub let name: String
        pub fun allowToOpenPacks(id: UInt64)
        pub fun createPackTemplate(name: String, description: String?, maxSupply: UInt32, imageUrl: String)
    }

    pub resource PackTemplateAdmin: PackTemplateAdminClaim {
        pub let name: String

        init() {
            self.name = "PackTemplateAdminClaim"
        }

        pub fun allowToOpenPacks(id: UInt64) {
            if let packTemplate = MFLPackTemplate.getPackTemplateRef(id: id) {
                packTemplate.allowToOpenPacks()
                emit AllowToOpenPacks(id: id)
            }
        }

        pub fun createPackTemplate(name: String, description: String?, maxSupply: UInt32, imageUrl: String) {
            let newPackTemplate <- create PackTemplate(
                name: name,
                description: description,
                maxSupply: maxSupply,
                imageUrl: imageUrl
            )

            emit Created(id: newPackTemplate.id)

            let oldPackTemplate <- MFLPackTemplate.packTemplates[newPackTemplate.id] <- newPackTemplate
            destroy oldPackTemplate
        }

        pub fun createPackTemplateAdmin(): @PackTemplateAdmin {
            return <- create PackTemplateAdmin()
        } 
    }



    init() {
        // Set our named paths
        self.PackTemplateAdminStoragePath = /storage/MFLPackTemplateAdmin

        // Initialize contract fields
        self.nextPackTemplateID = 1
        self.packTemplates <- {}

        // Create PackTemplateAdmin resource and save it to storage
        self.account.save(<- create PackTemplateAdmin() , to: self.PackTemplateAdminStoragePath)
        
        emit ContractInitialized()
    }
}
