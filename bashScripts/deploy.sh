#!/bin/bash

# This script deploys the contracts defined in flow.json to the emulator

# Create a new account
adminAlicePublicKey=f883d330db7932e1d65a9c6b04c2aa56249fc2848fa1dba14dfb463f05f92efe2cdeed7883a52025ff2acd72717622b2d2a215ebcac7a7e3321c2595c068f14b
flow accounts create --key ${adminAlicePublicKey}
sleep 2
flow project deploy -n emulator -f ./flow.json