/** 
  This script returns the available storage for a specific account.
**/

pub fun main(recipientAddr: Address) : Int64 {

    let recipient = getAccount(recipientAddr)

    let storageAvailable = Int64(recipient.storageCapacity) - Int64(recipient.storageUsed)

    return storageAvailable

}