import {getAccountAddress, getServiceAddress} from 'flow-js-testing';
import {testsUtils} from '../../_utils/tests.utils'

export const MFLClubTestsUtils = {

  async deployMFLClubContract(toAccountName) {
    const serviceAddress = await getServiceAddress();
    const to = await getAccountAddress(toAccountName);

    const addressMap = {};
    await testsUtils.deployContract('NonFungibleToken', serviceAddress, '_libs/NonFungibleToken', addressMap);
    await testsUtils.deployContract('MetadataViews', serviceAddress, '_libs/MetadataViews', addressMap);
    await testsUtils.deployContract('MFLAdmin', to, 'core/MFLAdmin', addressMap);
    await testsUtils.deployContract('MFLClub', to, 'clubs/MFLClub', addressMap);
    return addressMap;
  },

  async createClubAdmin(rootAdminAccountName, receiverAccountName) {
    const rootAdminAcctAddress = await getAccountAddress(rootAdminAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName);

    await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [receiverAcctAddress]});
    const args = [receiverAcctAddress, `/private/${receiverAccountName}-clubAdminClaim`];
    await testsUtils.shallPass({
      name: 'mfl/clubs/give_club_admin_claim.tx',
      args,
      signers: [rootAdminAcctAddress]
    });

    return receiverAcctAddress;
  },

  async createSquadAdmin(rootAdminAccountName, receiverAccountName) {
    const rootAdminAcctAddress = await getAccountAddress(rootAdminAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName);

    await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [receiverAcctAddress]});
    const args = [receiverAcctAddress, `/private/${receiverAccountName}-squadAdminClaim`];
    await testsUtils.shallPass({
      name: 'mfl/clubs/squads/give_squad_admin_claim.tx',
      args,
      signers: [rootAdminAcctAddress],
    });

    return receiverAcctAddress;
  },

  // async createClubNFT(id, playerAdminAccountName = 'AliceAdminAccount') {
  //   const adminAccountAddress = await getAccountAddress(playerAdminAccountName);
  //   const signers = [adminAccountAddress];
  //   const args = [
  //     id, MFLPlayerTestsUtils.PLAYER_DATA.season, MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
  //     ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY),
  //     adminAccountAddress
  //   ];
  //   return await testsUtils.shallPass({name: 'mfl/clubs/mint_club.tx', args, signers});
  // },

  // PLAYER_METADATA_DICTIONARY,

  // PLAYER_DATA: {
  //   id: 1,
  //   season: 1,
  //   folderCID: 'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm',
  //   metadata: PLAYER_METADATA_DICTIONARY,
  // },
};
