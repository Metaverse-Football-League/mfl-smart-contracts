#!/bin/bash

BLUE="\033[0;34m"
NC="\033[0m"

# This script buys packs

configPath="../../.."
signerAdminRoot=emulator-account
signerBob=bob-account
bobAddress=0x179b6b1cb6755e31

cd $configPath

while ! [[ "${nbrPacks}" =~ ^[0-9]+$ ]]
do 
    read -p "How many packs do you want to buy? (must be an unsigned int) : " nbrPacks
done
echo ""

echo -e "${BLUE}[Script] Get drops ids${NC}"
dropIDs=$(flow scripts execute ./scripts/mfl/drops/get_ids.script.cdc | grep -o '\[.*\]')
echo "Drops ids available: $dropIDs"

while ! [[ "${dropID}" =~ ^[0-9]+$ ]]
do 
    read -p "From which drop id? (must be an unsigned int) : " dropID
done
echo ""

echo -e "${BLUE}[Tx] Setup Bob's FUSD vault${NC}"
flow transactions send ./transactions/fusd/setup_account.tx.cdc --signer $signerBob
sleep 1

echo -e "${BLUE}[Script] Get Bob's FUSD vault balance${NC}"
currentBalance=$(flow scripts execute ./scripts/fusd/get_balance.script.cdc $bobAddress | grep -o '[0-9]*[.][0-9]*')
echo "Current Balance $currentBalance"

while ! [[ "${amountFUSD}" =~ ^[0-9]+[.][0-9]+$ ]]
do 
    read -p "How much FUSD do you want to receive (Expecting UFix64 : 0.00, 9.90, ...) :  " amountFUSD;
done


if [ -z $amountFUSD ]; then
    amountFUSD=0.00
fi

echo "------------------- INFOS BUY PACKS -------------------"
echo "Number of packs to buy: $nbrPacks"
echo -e "${BLUE}[Script] Get the price for this dropID${NC}"
price=$(flow scripts execute ./scripts/mfl/drops/get_drop.script.cdc $dropID | grep -o 'price: [0-9]*[.][0-9]*'  | cut -d ' ' -f 2)
if [ -z $price ]; then
    echo "Drop does not exist."
    exit 1
fi
amount=$(echo "$price * $nbrPacks" | bc)
currentBalance=$(echo "$currentBalance + $amountFUSD" | bc)
echo "Amount: $amount"
echo "Current Balance: $currentBalance"
echo "-------------------------------------------------------"

echo -e "${BLUE}[Tx] Send amountFUSD to Bob${NC}"
flow transactions send ./transactions/fusd/send_fusd.tx.cdc $bobAddress $amountFUSD --signer $signerAdminRoot
sleep 1

echo "Bob received $amountFUSD FUSD from service account"

echo -e "${BLUE}[Tx] Purchase packs with the previous values${NC}"
flow transactions send ./transactions/mfl/drops/purchase.tx.cdc $dropID $nbrPacks $amount --signer $signerBob

echo -e "${BLUE}[Script] Get packs${NC}"
flow scripts execute ./scripts/mfl/packs/get_packs_data_view_from_collection.script.cdc $bobAddress