#!/bin/bash

# This script buys packs and open them

configPath="../../.."
signerAdminRoot=emulator-account
signerBob=bob-account
bobAddress=0x179b6b1cb6755e31
amountFUSD="100.00"

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
echo "-------------------------------------------------------"

# Setup Bob's FUSD vault and send him amountFUSD
flow transactions send ./transactions/fusd/setup_account.tx.cdc --signer $signerBob
sleep 2
flow transactions send ./transactions/fusd/send_fusd.tx.cdc $bobAddress $amountFUSD --signer $signerAdminRoot
sleep 2

echo "Bob received $amountFUSD FUSD from service account"

# Send the tx with the previous values to purchase packs
flow transactions send ./transactions/mfl/drops/purchase.tx.cdc $dropID $nbrPacks $amount --signer $signerBob
