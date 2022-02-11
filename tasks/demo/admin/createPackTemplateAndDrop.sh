#!/bin/bash

# This script creates a new PackTemplate.

configPath="../../.."
signerAdminRoot=emulator-account
signerAdminAlice=admin-alice-account
adminAliceAddress=0x01cf0e2f2f715450
bobAddress=0x179b6b1cb6755e31

generateString () {
    echo $RANDOM | base64
}

cd $configPath

# PackTemplate creation
read -p $'Do you want default values for the PackTemplate? (Press Enter for yes)\n' -n1 packTemplateDefaultValues
echo ""
sleep 0.5

if [ -z $packTemplateDefaultValues ]; then
    packTemplateName=$(generateString)
    description=$(generateString)
    maxSupply=$RANDOM
    imageUrl="https://$(generateString).png"
else
    while [ -z "$packTemplateName" ]
    do 
        read -p "What is the pack template name? : " packTemplateName
    done

    read -p "What is the description? (optional) : " description

    while ! [[ "${maxSupply}" =~ ^[0-9]+$ ]]
    do 
        read -p "What is the max supply? (must be an unsigned int) : " maxSupply
    done

    while [ -z "$imageUrl" ]
    do 
        read -p "what is the imageUrl? : " imageUrl
    done
fi

echo "------------------- INFOS PACK TEMPLATE -------------------"
echo "Pack template name: $packTemplateName"
echo "Description: $description"
echo "Max supply: $maxSupply"
echo "Image url: $imageUrl"
echo "-----------------------------------------------------------"

# Get pack templates ids
packTemplatesIDs=$(flow scripts execute scripts/mfl/packs/get_pack_template_ids.script.cdc | grep -o "[0-9]")
currenPackTemplateID=$(echo "${packTemplatesIDs[*]}" | sort -nr | head -n1)
[ -z $currenPackTemplateID ] && nextPackTemplateID=1 || nextPackTemplateID="$(($currenPackTemplateID+1))"
echo "The pack template id will be : $nextPackTemplateID"
echo ""

# Drop creation
read -p $'Do you want default values for the drop? (Press Enter for yes)\n' -n1 dropDefaultValues
echo ""
sleep 0.5

if [ -z $dropDefaultValues ]; then
    dropName=$(generateString)
    price="$((1 + $RANDOM % 50)).00" # nbr between 1 and 50
    packTemplateID=$nextPackTemplateID # link to the packTemplate above
    maxTokensPerAddress=$((1 + $RANDOM % 20)) #nbr between 1 and 20
else
    while [ -z "$dropName" ]
    do 
        read -p "What is drop name? : " dropName
    done
    
    while ! [[ "${price}" =~ ^[0-9]+[.][0-9]+$ ]]
    do 
        read -p "What is the price of a pack? (must be a float ex: 9.50) : " price
    done
    
    while ! [[ "${packTemplateID}" =~ ^[0-9]+$ ]]
    do 
        read -p "What is the packTemplate id? (must be an unsigned int) : " packTemplateID
    done

    while ! [[ "${maxTokensPerAddress}" =~ ^[0-9]+$ ]]
    do 
        read -p "what is the maxTokensPerAddress? (must be an unsigned int) : " maxTokensPerAddress
    done
fi

read -p $'The drop is closed by default. Do you want to open it for whitelisted addresses (press 1) or to all (press 2). (Press Enter to pass) : \n' -n1 dropStatus
echo ""
if [ "$dropStatus" != 1 ] && [ "$dropStatus" != 2 ]; then
    dropStatus=0
fi

echo "------------------- INFOS DROP -------------------"
echo "Drop name: $dropName"
echo "Price: $price"
echo "Pack template id: $packTemplateID"
echo "Max tokens per address: $maxTokensPerAddress"
echo "Drop status: $dropStatus"
echo "--------------------------------------------------"

# Get drops ids
dropIDs=$(flow scripts execute scripts/mfl/drops/get_ids.script.cdc | grep -o "[0-9]")
currentDropID=$(echo "${dropIDs[*]}" | sort -nr | head -n1)
[ -z $currentDropID ] && nextDropID=1 || nextDropID="$(($currentDropID+1))"
echo "The drop id will be : $nextDropID"
echo ""

# Bob'account whitelisted or not
read -p $'Do you want to whitelist bob\'s address? (Press Enter to pass) : \n' -n1 bobIsWhitelisted
echo ""
if [ -n "$bobIsWhitelisted" ]; then
    while ! [[ "${bobNbrPacksWhitelist}" =~ ^[0-9]+$ ]] || [[ $bobNbrPacksWhitelist -gt $maxTokensPerAddress ]]
    do
        read -p $'What is the max number of packs he can buy? (must be an unsigned int and smaller or equal to the max tokens number per address)\n' bobNbrPacksWhitelist
    done
fi

# Create an admin proxy for Alice to be able to receive claims capability
flow transactions send ./transactions/mfl/core/create_admin_proxy.tx.cdc --signer $signerAdminAlice
sleep 1

# Give Alice a PackTemplate admin claim capability
flow transactions send ./transactions/mfl/packs/give_pack_template_admin_claim.tx.cdc $adminAliceAddress /private/packTemplateAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 1

# Alice can now create a pack template
flow transactions send ./transactions/mfl/packs/create_pack_template.tx.cdc $packTemplateName $description $maxSupply $imageUrl --signer $signerAdminAlice
sleep 1

# Allow pack opening for this pack template
flow transactions send ./transactions/mfl/packs/set_allow_to_open_packs.tx.cdc $nextPackTemplateID --signer $signerAdminAlice
sleep 1

# Script to execute if we want to check pack template infos :
flow scripts execute ./scripts/mfl/packs/get_pack_templates.script.cdc

# Give Alice a Drop admin claim capability
flow transactions send ./transactions/mfl/drops/give_drop_admin_claim.tx.cdc $adminAliceAddress /private/dropAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 1

# Alice can now create the drop
flow transactions send ./transactions/mfl/drops/create_drop.tx.cdc $dropName $price $packTemplateID $maxTokensPerAddress --signer $signerAdminAlice
sleep 1

# Setup Alice's FUSD vault
flow transactions send ./transactions/fusd/setup_account.tx.cdc --signer $signerAdminAlice
sleep 1

# Set owner vault
flow transactions send ./transactions/mfl/drops/set_owner_vault.tx.cdc --signer $signerAdminAlice
sleep 1

if [ ! -z $bobNbrPacksWhitelist ]; then
    flow transactions send ./transactions/mfl/drops/set_whitelisted_addresses.tx.cdc $nextDropID "{$bobAddress : $bobNbrPacksWhitelist}" --signer $signerAdminAlice
    sleep 1
fi

if [ "$dropStatus" == 1 ]; then
    # Open the drop to whitelisted addresses only
    flow transactions send ./transactions/mfl/drops/set_status_opened_whitelist.tx.cdc $nextDropID --signer $signerAdminAlice
    sleep 1
elif [ "$dropStatus" == 2 ]; then
    # Open the drop to all
    flow transactions send ./transactions/mfl/drops/set_status_opened_all.tx.cdc $nextDropID --signer $signerAdminAlice
    sleep 1
fi

# Script to get drops infos :
flow scripts execute ./scripts/mfl/drops/get_drops.script.cdc