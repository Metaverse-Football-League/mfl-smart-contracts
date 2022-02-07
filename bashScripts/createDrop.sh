#!/bin/bash

# This script creates a new Drop.

signerAdminRoot=emulator-account
signerAdminAlice=admin-alice-account
adminAliceAddress=0x01cf0e2f2f715450

echo -n "What is the drop name? : "
read dropName
echo -n "What is the pack price for this drop? : "
read price
echo -n "What is the pack template id linked to this drop? : "
read packTemplateID
echo -n "what is the maximum number of packs per address? : "
read maxTokensPerAddress

echo "------------------- INFOS -------------------"
echo "Drop name: $dropName"
echo "Price: $price"
echo "Pack template id: $packTemplateID"
echo "Max tokens per address: $maxTokensPerAddress"
echo "---------------------------------------------"

# Create an admin proxy for Alice to be able to receive claims capability
flow transactions send ../transactions/mfl/core/create_admin_proxy.tx.cdc --signer $signerAdminAlice
sleep 2
# Give Alice a Drop admin claim capability
flow transactions send ../transactions/mfl/drops/give_drop_admin_claim.tx.cdc $adminAliceAddress /private/dropAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 2
# Alice can now create the drop
flow transactions send ../transactions/mfl/drops/create_drop.tx.cdc $dropName $price $packTemplateID $maxTokensPerAddress --signer $signerAdminAlice


# Scripts to execute if we want to check drops infos :
# flow scripts execute ../scripts/mfl/drops/get_drops.script.cdc