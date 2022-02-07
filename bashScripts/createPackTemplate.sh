#!/bin/bash

# This script creates a new PackTemplate.

signerAdminRoot=emulator-account
signerAdminAlice=admin-alice-account
adminAliceAddress=0x01cf0e2f2f715450

echo -n "What is the pack template name? : "
read packTemplateName
echo -n "What is the description? : "
read description
echo -n "What is the max supply? : "
read maxSupply
echo -n "what is the imageUrl? : "
read imageUrl

echo "------------------- INFOS -------------------"
echo "Pack template name: $packTemplateName"
echo "Description: $description"
echo "Max supply: $maxSupply"
echo "Image url: $imageUrl"
echo "---------------------------------------------"

# Create an admin proxy for Alice to be able to receive claims capability
flow transactions send ../transactions/mfl/core/create_admin_proxy.tx.cdc --signer $signerAdminAlice
sleep 2
# Give Alice a PackTemplate admin claim capability
flow transactions send ../transactions/mfl/packs/give_pack_template_admin_claim.tx.cdc $adminAliceAddress /private/packTemplateAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 2
# Alice can now create a pack template
flow transactions send ../transactions/mfl/packs/create_pack_template.tx.cdc $packTemplateName $description $maxSupply $imageUrl --signer $signerAdminAlice
sleep 2
# Script to execute if we want to check pack template infos :
# flow scripts execute ../scripts/mfl/packs/get_pack_templates.script.cdc