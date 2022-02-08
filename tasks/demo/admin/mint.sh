#!/bin/bash

# This script mints an arbitrary nbr of Players.

configPath="../../.."
signerAdminRoot=emulator-account
signerAdminAlice=admin-alice-account
adminAliceAddress=0x01cf0e2f2f715450

cd $configPath

read -p "How many players do you want to mint? : " playersNbr

echo "------------------- INFOS MINTING PLAYERS -------------------"
echo "Number of players to mint: $playersNbr"
echo "---------------------------------------------"

# Create an admin proxy for Alice to be able to receive claims capability
flow transactions send ./transactions/mfl/core/create_admin_proxy.tx.cdc --signer $signerAdminAlice
sleep 2

# Give Alice a Player admin claim capability
flow transactions send ./transactions/mfl/players/give_player_admin_claim.tx.cdc $adminAliceAddress /private/playerAdminClaim_$adminAliceAddress --signer $signerAdminRoot
sleep 2

# Create Alice's Player Collection to be able to store players
flow transactions send ./transactions/mfl/players/create_and_link_player_collection.tx.cdc --signer $signerAdminAlice
sleep 2

# Alice can now mint players
i=1
until [ $i -gt $playersNbr ]
do
    flow transactions send ./transactions/mfl/players/mint_player.tx.cdc \
    $i \
    1 \
    QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco \
    Mathurin_$i \
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

# Script to execute if we want to check players infos :
# flow scripts execute ./scripts/mfl/players/get_players_data_view_from_collection.script.cdc $adminAliceAddress