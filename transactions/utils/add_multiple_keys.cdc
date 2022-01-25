/** 
  This tx creates an arbitrary number of proposal keys,
  with the same public key.
**/

transaction(numProposalKeys: UInt16) {  
  prepare(account: AuthAccount) {
    let key = account.keys.get(keyIndex: 0)!
    var count: UInt16 = 0
    while count < numProposalKeys {
      account.keys.add(
            publicKey: key.publicKey,
            hashAlgorithm: key.hashAlgorithm,
            weight: 1000.0
        )
        count = count + 1
    }
  }
}