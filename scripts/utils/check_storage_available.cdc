
pub fun main(recipientAddr: Address) : AnyStruct {

    let recipient = getAccount(recipientAddr)

    let storageAvailable = Int64(recipient.storageCapacity) - Int64(recipient.storageUsed)

    return storageAvailable

}