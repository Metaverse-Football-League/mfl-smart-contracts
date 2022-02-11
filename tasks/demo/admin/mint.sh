#!/bin/bash

BLUE="\033[0;34m"
NC="\033[0m"

# This script mints an arbitrary nbr of Players.

configPath="../../.."
signerAdminRoot=emulator-account
signerAdminAlice=admin-alice-account
adminAliceAddress=0x01cf0e2f2f715450

cd $configPath

while ! [[ "${playersNbr}" =~ ^[0-9]+$ ]]
do 
    read -p "How many players do you want to mint? (must be an unsigned int) : " playersNbr
done

echo "------------------- INFOS MINTING PLAYERS -------------------"
echo "Number of players to mint : $playersNbr"
echo "---------------------------------------------"

echo -e "${BLUE}[Tx] Create an admin proxy for Alice to be able to receive claims capability${NC}"
flow transactions send ./transactions/mfl/core/create_admin_proxy.tx.cdc --signer $signerAdminAlice
sleep 1

echo -e "${BLUE}[Tx] Give Alice a Player admin claim capability${NC}"
flow transactions send ./transactions/mfl/players/give_player_admin_claim.tx.cdc $adminAliceAddress /private/playerAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 1

echo -e "${BLUE}[Tx] Create Alice's Player Collection to be able to store players${NC}"
flow transactions send ./transactions/mfl/players/create_and_link_player_collection.tx.cdc --signer $signerAdminAlice
sleep 1

# Alice can now mint players
i=1
until [ $i -gt $playersNbr ]
do
    echo -e "${BLUE}[Tx] Mint player nbr $i${NC}"
    flow transactions send ./transactions/mfl/players/mint_player.tx.cdc \
    $i \
    1 \
    QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco \
    Player_$i \
    '["FR, BR"]'\
    '["GK"]'\
    left \
    20 \
    180 \
    89 \
    75 \
    86 \
    90 \
    84 \
    80 \
    88 \
    52 \
    hash_potential \
    98 \
    --signer $signerAdminAlice 
    sleep 1
    ((i++))
done

echo -e "${BLUE}[Script] Get players from collection${NC}"
flow scripts execute ./scripts/mfl/players/get_players_data_view_from_collection.script.cdc $adminAliceAddress