#!/bin/bash

BLUE="\033[0;34m"
NC="\033[0m"

# This script opens a pack

configPath="../../.."
signerBob=bob-account
bobAddress=0x179b6b1cb6755e31

cd $configPath

echo -e "${BLUE}[Script] Get packs ids on Bob's Collection${NC}"
getPackIdsResult=$(flow scripts execute ./scripts/mfl/packs/get_ids_in_collection.script.cdc $bobAddress)
currentPackIDs=$(echo $getPackIdsResult | perl -0777 -pe 's/^.*Result: \[(.*?[0-9])\]$/\1/')
echo "Packs ids in your wallet : "
if ! [[ $currentPackIDs =~ [0-9] ]]; then
    echo "None"
    exit 0
else
    echo $currentPackIDs
fi

while ! [[ "${packIDToOpen}" =~ ^[0-9]+$ ]]
do 
    read -p "Which pack do you want to open? (must be an unsigned int) : " packIDToOpen
done

echo -e "${BLUE}[Tx] Open the pack with id $packIDToOpen${NC}"
flow transactions send ./transactions/mfl/packs/open_pack.tx.cdc $packIDToOpen --signer $signerBob
sleep 1

echo -e "${BLUE}[Script] Get packs${NC}"
flow scripts execute ./scripts/mfl/packs/get_packs_data_view_from_collection.script.cdc $bobAddress