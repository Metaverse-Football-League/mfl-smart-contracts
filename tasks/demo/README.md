# Demo

## Introduction

This folder contains a series of scripts that aim to reproduce typical workflows of MFL logic. These scripts run on the emulator where 3 accounts are created :
- `emulator-account` : Contracts are deployed here. It's the admin root.
- `admin-alice-account` : Admin account who will receive admin rights throughout the workflow.
- `bob-account` : Standard user account.
  
These 3 accounts are defined in the main configuration `flow.json` file. It can be easier between the different scenarios to start from scratch by restarting your emulator.

## Explanations

To simulate a workflow, the scripts must be launched in a precise order. You must be in the corresponding folder to run the scripts (/admin or /user).

At the end of each bash script, a flow script is executed to allow you to check the current status of contracts or accounts.

1. `admin/deploysContracts.sh` : create the accounts and deploy the contracts.
   
2. `admin/createPackTemplateAndDrop.sh`: create a pack template and a drop (this script gives alice the rights to create drops and pack templates). You can choose the default values or enter your own values. You must then indicate the status of the drop. Finally, you will be asked if bob's account should be whitelisted and if so to indicate the maximum number of packs he can buy in whitelist mode.
   
3. `user/buyPack.sh`: Bob can now buy packs for a specific drop. You can specify the amount of FUSD he will receive in his account (to buy his packs).
   
4. `user/openPack.sh`: Bob can now open packs that he bought in (3).You must indicate which pack id to open.

The `admin/mint.sh` script can be run at anytime (but after `admin/deploysContracts.sh`) to simulate the minting of an arbitrary number of players. During this script, Alice receives the admin rights to mint players.