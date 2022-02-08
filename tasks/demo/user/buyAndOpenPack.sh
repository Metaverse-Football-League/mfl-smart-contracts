#!/bin/bash

# This script buys packs and open them

configPath="../../.."
signerBob=bob-account

cd $configPath

read -p "How many packs do you want to buy? : " nbrPacks
read -p "From which drop id? : " dropID

echo "------------------- INFOS BUY PACKS -------------------"
echo "Number of packs to buy: $nbrPacks"
price=$(flow scripts execute ./scripts/mfl/drops/get_drop.script.cdc $dropID | grep -o 'price: [0-9]*[.][0-9]*'  | cut -d ' ' -f 2)
if [ -z $price ]; then
    echo "Drop does not exist."
    exit 1
fi
amount=$(echo "$price * $nbrPacks" | bc)
echo "Amount: " $amount
echo "---------------------------------------------"

# Create Bob's Pack Collection to be able to store packs
flow transactions send ./transactions/mfl/packs/create_and_link_pack_collection.tx.cdc --signer $signerBob

# Send the tx with the previous values to purchase packs
flow transactions send ./transactions/mfl/drops/purchase.tx.cdc $dropID $nbrPacks $amount --signer $signerBob
