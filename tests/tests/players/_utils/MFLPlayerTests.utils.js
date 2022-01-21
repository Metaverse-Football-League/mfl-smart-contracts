import {getAccountAddress, getServiceAddress} from 'flow-js-testing';
import {testsUtils} from '../../_utils/tests.utils';

const PLAYER_METADATA_DICTIONARY = {
  name: 'some name',
  nationalities: ['FR', 'DE'],
  positions: ['ST', 'CAM'],
  preferredFoot: 'left',
  ageAtMint: 17,
  height: 180,
  overall: 87,
  pace: 56,
  shooting: 66,
  passing: 62,
  dribbling: 61,
  defense: 60,
  physical: 59,
  goalkeeping: 1,
  potential: 'someHash',
  resistance: 65,
};

export const MFLPlayerTestsUtils = {

  async deployMFLPlayerContract(toAccountName) {
    const serviceAddress = await getServiceAddress();
    const to = await getAccountAddress(toAccountName);

    const addressMap = {};
    await testsUtils.deployContract('NonFungibleToken', serviceAddress, '_libs/NonFungibleToken', addressMap);
    await testsUtils.deployContract('FUSD', serviceAddress, '_libs/FUSD', addressMap);
    await testsUtils.deployContract('MFLAdmin', to, 'core/MFLAdmin', addressMap);
    await testsUtils.deployContract('MFLPlayer', to, 'players/MFLPlayer', addressMap);
    return addressMap;
  },

  async createPlayerAdmin(rootAdminAccountName, receiverAccountName) {
    const rootAdminAcctAddress = await getAccountAddress(rootAdminAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName);

    await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [receiverAcctAddress]});
    const args = [receiverAcctAddress, `/private/${receiverAccountName}-playerAdminClaim`];
    await testsUtils.shallPass({
      name: 'mfl/players/give_player_admin_claim.tx',
      args,
      signers: [rootAdminAcctAddress],
    });

    return receiverAcctAddress;
  },

  async createPlayerNFT(playerID, playerAdminAccountName = 'AliceAdminAccount') {
    const adminAccountAddress = await getAccountAddress(playerAdminAccountName);
    const signers = [adminAccountAddress];
    const args = [
      playerID, MFLPlayerTestsUtils.PLAYER_METADATA.season, MFLPlayerTestsUtils.PLAYER_METADATA.ipfsURI,
      ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY),
    ];
    return await testsUtils.shallPass({name: 'mfl/players/mint_player.tx', args, signers});
  },

  PLAYER_METADATA_DICTIONARY,

  PLAYER_METADATA: {
    playerID: 1,
    season: 1,
    ipfsURI: 'ipfs://someURI/1201',
    metadata: PLAYER_METADATA_DICTIONARY,
  },
};
