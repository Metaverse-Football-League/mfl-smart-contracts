/**
  This contract allows MFL to create and manage packTemplates.
  A packTemplate is in a way the skeleton of a pack, where, among other things,
  a max supply and  current supply are defined,
  and whether or not packs linked to a packTemplate can be opened.
**/

pub contract MFLPackTemplate {

    // Events
    pub event ContractInitialized()
    pub event Minted(id: UInt64)
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
        pub let isOpenable: Bool
        pub let imageUrl: String
        pub let type: String
        access(contract) let slots: [Slot]

        init(
            id: UInt64,
            name: String,
            description: String?,
            maxSupply: UInt32,
            currentSupply: UInt32,
            isOpenable: Bool,
            imageUrl: String,
            type: String,
            slots: [Slot]
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.maxSupply = maxSupply
            self.currentSupply = currentSupply
            self.isOpenable = isOpenable
            self.imageUrl = imageUrl
            self.type = type
            self.slots = slots
        }
    }

    pub struct Slot {
        pub let type: String
        access(contract) let chances: {String: String}
        pub let count: UInt32

        init(type: String, chances: {String: String}, count: UInt32) {
            self.type = type
            self.chances = chances
            self.count = count
        }
    }

    pub resource PackTemplate {
        pub let id: UInt64
        access(contract) let name: String
        access(contract) let description: String?
        access(contract) let maxSupply: UInt32
        access(contract) var currentSupply: UInt32
        access(contract) var isOpenable: Bool
        access(contract) var imageUrl: String
        access(contract) let type: String
        access(contract) let slots: [Slot]

        init(name: String, description: String?, maxSupply: UInt32, imageUrl: String, type: String, slots: [Slot]) {
            self.id = MFLPackTemplate.nextPackTemplateID
            MFLPackTemplate.nextPackTemplateID = MFLPackTemplate.nextPackTemplateID + (1 as UInt64)
            self.name = name
            self.description = description
            self.maxSupply = maxSupply
            self.currentSupply = 0
            self.isOpenable = false
            self.imageUrl = imageUrl
            self.type = type
            self.slots = slots
            emit Minted(id: self.id)
        }

        // Enable accounts to open their packs
        access(contract) fun allowToOpenPacks() {
            self.isOpenable = true
        }

        // Increase current supply
        access(contract) fun increaseCurrentSupply(nbToMint: UInt32) {
            pre {
                nbToMint <=  self.maxSupply - self.currentSupply : "Supply exceeded"
            }
            self.currentSupply = self.currentSupply + nbToMint
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
                isOpenable: packTemplate.isOpenable,
                imageUrl: packTemplate.imageUrl,
                type: packTemplate.type,
                slots: packTemplate.slots
            )
        }
        return nil
    }

    // Get a data reprensation of all packTemplates
    pub fun getPackTemplates(): [PackTemplateData] {
        var packTemplatesData: [PackTemplateData] = []
        for id in self.getPackTemplatesIDs() {
            if let packTemplate = self.getPackTemplate(id: id) {
                packTemplatesData.append(packTemplate)
            }
        }
        return packTemplatesData
    }

    // Get a specif packTemplate ref (in particular for calling admin methods)
    access(contract) fun getPackTemplateRef(id: UInt64): &MFLPackTemplate.PackTemplate? {
        return &self.packTemplates[id] as auth &MFLPackTemplate.PackTemplate?
    }

    // Called from MFLPack batchMintPack fct
    access(account) fun increasePackTemplateCurrentSupply(id: UInt64, nbToMint: UInt32) {
        self.getPackTemplateRef(id: id)?.increaseCurrentSupply(nbToMint: nbToMint)
    }
    
    // This interface allows any account that has a private capability to a PackTemplateAdminClaim to call the methods below
    pub resource interface PackTemplateAdminClaim {
        pub let name: String
        pub fun allowToOpenPacks(id: UInt64)
        pub fun createPackTemplate(name: String, description: String?, maxSupply: UInt32, imageUrl: String, type: String, slots: [Slot])
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

        pub fun createPackTemplate(name: String, description: String?, maxSupply: UInt32, imageUrl: String, type: String, slots: [Slot]) {
            let newPackTemplate <- create PackTemplate(
                name: name,
                description: description,
                maxSupply: maxSupply,
                imageUrl: imageUrl,
                type: type,
                slots: slots
            )
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
