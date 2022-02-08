#!/bin/bash

# This script creates a new PackTemplate.

configPath="../../.."
signerAdminRoot=emulator-account
signerAdminAlice=admin-alice-account
adminAliceAddress=0x01cf0e2f2f715450

generateString () {
    echo $RANDOM | base64
}

cd $configPath

# PackTemplate creation

read -p $'Do you want default values for the PackTemplate? (Enter: yes)\n' -n1 packTemplateDefaultValues
echo ""
sleep 0.5

if [ -z $packTemplateDefaultValues ]; then
    packTemplateName=$(generateString)
    description=$(generateString)
    maxSupply=$RANDOM
    imageUrl="https://$(generateString).png"
else
    read -p "What is the pack template name? : " packTemplateName
    read -p "What is the description? : " description
    read -p "What is the max supply? : " maxSupply
    read -p "what is the imageUrl? : " imageUrl
fi

echo "------------------- INFOS PACK TEMPLATE -------------------"
echo "Pack template name: $packTemplateName"
echo "Description: $description"
echo "Max supply: $maxSupply"
echo "Image url: $imageUrl"
echo "-----------------------------------------------------------"

# Drop creation

read -p $'Do you want default values for the drop? (Enter: yes)\n' -n1 dropDefaultValues
echo ""
sleep 0.5

if [ -z $dropDefaultValues ]; then
    dropName=$(generateString)
    price="$((1 + $RANDOM % 50)).00" # nbr between 1 and 50
    packTemplateID=1 # link to the packTemplate above
    maxTokensPerAddress=$((1 + $RANDOM % 20)) #nbr between 1 and 20
else
    read -p "What is drop name? : " dropName
    read -p "What is the price of a pack? : " price
    read -p "What is the packTemplate id? : " packTemplateID
    read -p "what is the maxTokensPerAddress? : " maxTokensPerAddress
fi

dropStatus=0
until [ "$dropStatus" == 1 ] || [ "$dropStatus" == 2 ] || [ "$dropStatus" == 3 ] 
do
    read -p $'What is the status of the drop?: 1=closed 2=opened_whitelist 3=opened_all\n' -n1 dropStatus;
    echo ""
done

#TODO enter whitelist addresses ?

echo "------------------- INFOS DROP -------------------"
echo "Drop name: $dropName"
echo "Price: $price"
echo "Pack template id: $packTemplateID"
echo "Max tokens per address: $maxTokensPerAddress"
echo "Drop status: $dropStatus"
echo "--------------------------------------------------"

# Create an admin proxy for Alice to be able to receive claims capability
flow transactions send ./transactions/mfl/core/create_admin_proxy.tx.cdc --signer $signerAdminAlice
sleep 2

# Give Alice a PackTemplate admin claim capability
flow transactions send ./transactions/mfl/packs/give_pack_template_admin_claim.tx.cdc $adminAliceAddress /private/packTemplateAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 2

# Alice can now create a pack template
flow transactions send ./transactions/mfl/packs/create_pack_template.tx.cdc $packTemplateName $description $maxSupply $imageUrl --signer $signerAdminAlice
sleep 2

# Script to execute if we want to check pack template infos :
# flow scripts execute ./scripts/mfl/packs/get_pack_templates.script.cdc

# Give Alice a Drop admin claim capability
flow transactions send ./transactions/mfl/drops/give_drop_admin_claim.tx.cdc $adminAliceAddress /private/dropAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 2

# Alice can now create the drop
flow transactions send ./transactions/mfl/drops/create_drop.tx.cdc $dropName $price $packTemplateID $maxTokensPerAddress --signer $signerAdminAlice

if [ "$dropStatus" == 2 ]; then
    # Open the drop to whitelisted addresses only
    flow transactions send ./transactions/mfl/drops/set_status_opened_whitelist.tx.cdc $dropID --signer $signerAdminAlice
elif [ "$dropStatus" == 3 ]; then
    # Open the drop to all
    flow transactions send ./transactions/mfl/drops/set_status_opened_all.tx.cdc $dropID --signer $signerAdminAlice
fi

# Scripts to execute if we want to check drops infos :
# flow scripts execute ./scripts/mfl/drops/get_drops.script.cdc