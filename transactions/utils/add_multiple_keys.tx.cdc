/** 
  This tx creates an arbitrary number of keys,
  with the same public key.
**/

transaction(numProposalKeys: UInt16, keyIndex: Int) {  
  prepare(account: AuthAccount) {
    let key = account.keys.get(keyIndex: keyIndex)!
    var count: UInt16 = 0
    while count < numProposalKeys {
      account.keys.add(
            publicKey: key.publicKey,
            hashAlgorithm: key.hashAlgorithm,
            weight: 0.0
        )
        count = count + 1
    }
  }
}