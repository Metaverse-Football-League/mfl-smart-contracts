#!/bin/bash

# This script opens a pack

configPath="../../.."
signerBob=bob-account
bobAddress=0x179b6b1cb6755e31

cd $configPath

# Get packs ids on Bob's Collection
packsIDs=$(flow scripts execute ./scripts/mfl/packs/get_ids_in_collection.script.cdc $bobAddress | grep -o '\[.*\]')
echo $packsIDs
read -p "Which pack do you want to open? : " packIDToOpen

# Send the tx with to open this pack
flow transactions send ./transactions/mfl/packs/open_pack.tx.cdc $packIDToOpen --signer $signerBob
sleep 1

# Script to get packs infos :
flow scripts execute ./scripts/mfl/packs/get_packs_data_view_from_collection.script.cdc $bobAddress