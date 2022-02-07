#!/bin/bash

# This script buys packs NFT for a specific drop.

bobAddress=0x01cf0e2f2f715450
signerBob=bob-account

echo -n "From which drop? : "
read dropID
echo -n "How many packs to buy? : "
read nbToMint

echo "------------------- INFOS -------------------"
echo "Drop id: $dropID"
echo "Number of packs: $nbToMint"
price=$(flow scripts execute ../scripts/mfl/drops/get_drop.script.cdc $dropID | grep -o 'price: [0-9]*[.][0-9]*'  | cut -d ' ' -f 2)
if [ -z $price]; then
    echo "Drop does not exist."
    exit 1
fi
amount=$(echo "$price * $nbToMint" | bc)
echo "Amount: " $amount
echo "---------------------------------------------"

# Send the tx with the previous values
flow transactions send ../transactions/mfl/drops/purchase.tx.cdc $dropID $nbToMint $amount --signer 0x01cf0e2f2f715450
