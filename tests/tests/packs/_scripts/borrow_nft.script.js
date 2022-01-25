export const BORROW_NFT = `
    import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
    import MFLPack from "../../../../contracts/packs/MFLPack.cdc"

    pub fun main(address: Address, packID: UInt64): &NonFungibleToken.NFT {
        let packCollectionRef = getAccount(address).getCapability<&{MFLPack.CollectionPublic}>(MFLPack.CollectionPublicPath).borrow()
            ?? panic("Could not borrow the collection reference")
        let nftRef = packCollectionRef.borrowNFT(id: packID)
        return nftRef
    }
` 