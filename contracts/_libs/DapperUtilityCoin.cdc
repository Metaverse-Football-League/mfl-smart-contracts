import FungibleToken from "./FungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import FungibleTokenMetadataViews from "./FungibleTokenMetadataViews.cdc"

access(all) contract DapperUtilityCoin : FungibleToken {

    // Total supply of DapperUtilityCoins in existence
    access(all) var totalSupply: UFix64

    // Event that is emitted when tokens are withdrawn from a Vault
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited to a Vault
    access(all) event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when new tokens are minted
    access(all) event TokensMinted(amount: UFix64)

    // Event that is emitted when tokens are destroyed
    access(all) event TokensBurned(amount: UFix64)

    // Event that is emitted when a new minter resource is created
    access(all) event MinterCreated(allowedAmount: UFix64)

    // Event that is emitted when a new burner resource is created
    access(all) event BurnerCreated()

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    access(all) resource Vault: FungibleToken.Vault {
        access(all) event ResourceDestroyed(id: UInt64 = self.uuid, balance: UFix64 = self.balance)

        // holds the balance of a users tokens
        access(all) var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        /// Called when a fungible token is burned via the `Burner.burn()` method
        access(contract) fun burnCallback() {
            if self.balance > 0.0 {
                DapperUtilityCoin.totalSupply = DapperUtilityCoin.totalSupply - self.balance
            }
            self.balance = 0.0
        }

       /// Asks if the amount can be withdrawn from this vault
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return amount <= self.balance
        }

        access(all) view fun getViews(): [Type] {
            return DapperUtilityCoin.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return DapperUtilityCoin.resolveContractView(resourceType: nil, viewType: view)
        }

        /// Get the balance of the vault
        access(all) view fun getBalance(): UFix64 {
            return self.balance
        }

        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @DapperUtilityCoin.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @DapperUtilityCoin.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }
        /// Returns the storage path where the vault should typically be stored
        access(all) view fun getDefaultStoragePath(): StoragePath? {
            return /storage/dapperUtilityCoinVault
        }

        /// Returns the public path where this vault should have a public capability
        access(all) view fun getDefaultPublicPath(): PublicPath? {
            return /public/dapperUtilityCoinVault
        }

        /// Returns the public path where this vault's Receiver should have a public capability
        access(all) view fun getDefaultReceiverPath(): PublicPath? {
            return nil
        }

       access(all) fun createEmptyVault(): @DapperUtilityCoin.Vault {
           return <-create Vault(balance: 0.0)
       }

    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    access(all) fun createEmptyVault(vaultType: Type): @DapperUtilityCoin.Vault {
        return <-create Vault(balance: 0.0)
    }


    access(all) resource Administrator {
        // createNewMinter
        //
        // Function that creates and returns a new minter resource
        //
        access(all) fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        // createNewBurner
        //
        // Function that creates and returns a new burner resource
        //
        access(all) fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    // Minter
    //
    // Resource object that token admin accounts can hold to mint new tokens.
    //
    access(all) resource Minter {

        // the amount of tokens that the minter is allowed to mint
        access(all) var allowedAmount: UFix64

        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        access(all) fun mintTokens(amount: UFix64): @DapperUtilityCoin.Vault {
            pre {
                amount > UFix64(0): "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            DapperUtilityCoin.totalSupply = DapperUtilityCoin.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    // Burner
    //
    // Resource object that token admin accounts can hold to burn tokens.
    //
    access(all) resource Burner {

        // burnTokens
        //
        // Function that destroys a Vault instance, effectively burning the tokens.
        //
        // Note: the burned tokens are automatically subtracted from the
        // total supply in the Vault destructor.
        //
        access(all) fun burnTokens(from: @DapperUtilityCoin.Vault) {
            let vault <- from as! @DapperUtilityCoin.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                        url: "https://assets-global.website-files.com/603804a7f3c274da06bf9153/60380558c03f544189766973_dapper_logo.png"
                    ),
                    mediaType: "image/svg+xml"
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Dapper Utility Coin",
                    symbol: "DUC",
                    description: "",
                    externalURL: MetadataViews.ExternalURL("https://www.dapperlabs.com/"),
                    logos: medias,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/dapperlabs")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: /storage/dapperUtilityCoinVault,
                    receiverPath: /public/dapperUtilityCoinVault,
                    metadataPath: /public/dapperUtilityCoinVault,
                    receiverLinkedType: Type<&{FungibleToken.Vault}>(),
                    metadataLinkedType: Type<&{FungibleToken.Vault}>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-DapperUtilityCoin.createEmptyVault(vaultType: Type<@DapperUtilityCoin.Vault>())
                    })
                )
        }
        return nil
    }


    init() {
        // we're using a high value as the balance here to make it look like we've got a ton of money,
        // just in case some contract manually checks that our balance is sufficient to pay for stuff
        self.totalSupply = 999999999.0

        let admin <- create Administrator()
        let minter <- admin.createNewMinter(allowedAmount: self.totalSupply)
        self.account.storage.save(<-admin, to: /storage/dapperUtilityCoinAdmin)


        // mint tokens
        let tokenVault <- minter.mintTokens(amount: self.totalSupply)
        self.account.storage.save(<-tokenVault, to: /storage/dapperUtilityCoinVault)
        destroy minter

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        let vaultCap = self.account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/dapperUtilityCoinVault)
        self.account.capabilities.publish(vaultCap, at: /public/dapperUtilityCoinVault)
    }
}
