transaction(startIndex: Int, endIndex: Int) {
    prepare(signer: AuthAccount) {
        pre {
            startIndex <= endIndex : "startIndex must lower than endIndex"
        }
        // Get a key from an auth account.
        var i = startIndex
        while i < endIndex {
            signer.keys.revoke(keyIndex: i)
            i = i + 1
        }
    }
}