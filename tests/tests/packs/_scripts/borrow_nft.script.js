export const BORROW_NFT = `
    import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
    import MFLPack from "../../../../contracts/packs/MFLPack.cdc"

    access(all)
    fun main(address: Address, packID: UInt64): &{NonFungibleToken.NFT}? {
        let packCollectionRef = getAccount(address).capabilities.borrow<&MFLPack.Collection>(MFLPack.CollectionPublicPath)
            ?? panic("Could not borrow the collection reference")
        let nftRef = packCollectionRef.borrowNFT(packID)
        return nftRef
    }
`
