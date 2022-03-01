#!/bin/bash

BLUE="\033[0;34m"
NC="\033[0m"

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

echo -e "${BLUE}[Script] Get pack templates ids${NC}"
getPackTemplateIdsResult=$(flow scripts execute scripts/mfl/packs/get_pack_template_ids.script.cdc)
currentPackTemplateID=$(echo $getPackTemplateIdsResult | perl -0777 -pe 's/^.*Result: \[.*?([0-9]+)\]$/\1/')
re='^[0-9]+$'
if ! [[ $currentPackTemplateID =~ $re ]] ; then
    nextPackTemplateID=1
else
    nextPackTemplateID="$(($currentPackTemplateID+1))"
fi

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
    maxTokensPerAddress=$((10 + $RANDOM % 20)) #nbr between 10 and 30
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

read -p $'The drop is opened to all by default. Do you want to open it only for whitelisted addresses (press 1) or close it (press 0). (Press Enter to pass) : \n' -n1 dropStatus
echo ""
if [ "$dropStatus" != 1 ] && [ "$dropStatus" != 0 ]; then
    dropStatus=2
fi

echo "------------------- INFOS DROP -------------------"
echo "Drop name: $dropName"
echo "Price: $price"
echo "Pack template id: $packTemplateID"
echo "Max tokens per address: $maxTokensPerAddress"
echo "Drop status: $dropStatus"
echo "--------------------------------------------------"

echo -e "${BLUE}[Script] Get drops ids${NC}"
getDropIdsResult=$(flow scripts execute scripts/mfl/drops/get_ids.script.cdc)
currentDropID=$(echo $getDropIdsResult | perl -0777 -pe 's/^.*Result: \[.*?([0-9]+)\]$/\1/')
re='^[0-9]+$'
if ! [[ $currentDropID =~ $re ]] ; then
    nextDropID=1
else
    nextDropID="$(($currentDropID+1))"
fi
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

echo -e "${BLUE}[Tx] Create an admin proxy for Alice to be able to receive claims capability${NC}"
flow transactions send ./transactions/mfl/core/create_admin_proxy.tx.cdc --signer $signerAdminAlice
sleep 1

echo -e "${BLUE}[Tx] Give Alice a PackTemplate admin claim capability${NC}"
flow transactions send ./transactions/mfl/packs/give_pack_template_admin_claim.tx.cdc $adminAliceAddress /private/packTemplateAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 1

echo -e "${BLUE}[Tx] Alice can now create a pack template${NC}"
flow transactions send ./transactions/mfl/packs/create_pack_template.tx.cdc $packTemplateName $description $maxSupply $imageUrl "BASE" 0 [] [] [] --signer $signerAdminAlice
sleep 1

echo -e "${BLUE}[Tx] Allow pack opening for this pack template${NC}"
flow transactions send ./transactions/mfl/packs/set_allow_to_open_packs.tx.cdc $nextPackTemplateID --signer $signerAdminAlice
sleep 1

echo -e "${BLUE}[Script] Get all pack templates${NC}"
flow scripts execute ./scripts/mfl/packs/get_pack_templates.script.cdc

echo -e "${BLUE}[Tx] Give Alice a Drop admin claim capability${NC}"
flow transactions send ./transactions/mfl/drops/give_drop_admin_claim.tx.cdc $adminAliceAddress /private/dropAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 1

echo -e "${BLUE}[Tx] Alice creates the drop${NC}"
flow transactions send ./transactions/mfl/drops/create_drop.tx.cdc $dropName $price $packTemplateID $maxTokensPerAddress --signer $signerAdminAlice
sleep 1

echo -e "${BLUE}[Tx] Setup Alice's FUSD vault${NC}"
flow transactions send ./transactions/fusd/setup_account.tx.cdc --signer $signerAdminAlice
sleep 1

echo -e "${BLUE}[Tx] Set drop owner vault${NC}"
flow transactions send ./transactions/mfl/drops/set_owner_vault.tx.cdc --signer $signerAdminAlice
sleep 1

if [ ! -z $bobNbrPacksWhitelist ]; then
    echo -e "${BLUE}[Tx] Add bob to whitelisted addresses${NC}"
    flow transactions send ./transactions/mfl/drops/set_whitelisted_addresses.tx.cdc $nextDropID "{$bobAddress : $bobNbrPacksWhitelist}" --signer $signerAdminAlice
    sleep 1
fi

if [ "$dropStatus" == 1 ]; then
    echo -e "${BLUE}[Tx] Open the drop to whitelisted addresses only${NC}"
    flow transactions send ./transactions/mfl/drops/set_status_opened_whitelist.tx.cdc $nextDropID --signer $signerAdminAlice
    sleep 1
elif [ "$dropStatus" == 2 ]; then
    echo -e "${BLUE}[Tx] Open the drop to all${NC}"
    flow transactions send ./transactions/mfl/drops/set_status_opened_all.tx.cdc $nextDropID --signer $signerAdminAlice
    sleep 1
fi

echo -e "${BLUE}[Script] Get drops${NC}"
flow scripts execute ./scripts/mfl/drops/get_drops.script.cdc
