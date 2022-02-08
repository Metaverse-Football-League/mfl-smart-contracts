#!/bin/bash

# This script deploys the contracts defined in flow.json to the emulator

configPath='./flow.json'

# Create new accounts
adminAlicePublicKey=f883d330db7932e1d65a9c6b04c2aa56249fc2848fa1dba14dfb463f05f92efe2cdeed7883a52025ff2acd72717622b2d2a215ebcac7a7e3321c2595c068f14b
bobPublicKey=44d8f372b1ed66b0ca2069ddb4ccfca040eb6c1b4a370fc0644c56a51458e1f9b483b5554f97616850c1fc623666fe87f35a3d1ad94107f1b2717934929015cf

flow accounts create --key ${adminAlicePublicKey} -f $configPath
sleep 2
flow accounts create --key ${bobPublicKey} -f $configPath
sleep 2
flow project deploy -n emulator -f $configPath