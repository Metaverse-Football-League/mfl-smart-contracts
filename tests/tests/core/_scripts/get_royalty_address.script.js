export const GET_ROYALTY_ADDRESS = `
  import MFLAdmin from "../../../contracts/players/MFLAdmin.cdc"
  
  pub fun main(): Address {
      return MFLAdmin.royaltyAddress()
  }
`
