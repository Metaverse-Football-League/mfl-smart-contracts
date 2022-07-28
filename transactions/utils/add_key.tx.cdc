/** 
  This tx adds a new key to the account .
**/

transaction(publicKey: String) {

    prepare(acct: AuthAccount) {
        let bytes = publicKey.decodeHex()
        let key = PublicKey(
            publicKey: bytes,
            signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
        )
        acct.keys.add(
            publicKey: key,
            hashAlgorithm: HashAlgorithm.SHA3_256,
            weight: 1000.0
        )
    }

    execute {

    }
}
