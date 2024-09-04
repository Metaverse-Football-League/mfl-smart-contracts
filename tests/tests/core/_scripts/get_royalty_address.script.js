export const GET_ROYALTY_ADDRESS = `
  import MFLAdmin from "../../../contracts/players/MFLAdmin.cdc"
  
  access(all)
  fun main(): Address {
      return MFLAdmin.royaltyAddress()
  }
`
