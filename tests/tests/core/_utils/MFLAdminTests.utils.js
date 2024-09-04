import {getAccountAddress, getServiceAddress} from '@onflow/flow-js-testing';
import {testsUtils} from '../../_utils/tests.utils';

export const MFLAdminTestsUtils = {

  async deployMFLAdminContract(toAccountName) {
    const serviceAddress = await getServiceAddress();
    const to = await getAccountAddress(toAccountName);

    const addressMap = {};
    await testsUtils.deployContract('NonFungibleToken', serviceAddress, '_libs/NonFungibleToken', addressMap);
    await testsUtils.deployContract('MetadataViews', serviceAddress, '_libs/MetadataViews', addressMap);
    await testsUtils.deployContract('MFLAdmin', to, 'core/MFLAdmin', addressMap);
    await testsUtils.deployContract('MFLPackTemplate', to, 'packs/MFLPackTemplate', addressMap);
    await testsUtils.deployContract('MFLViews', to, 'views/MFLViews', addressMap);
    await testsUtils.deployContract('MFLPlayer', to, 'players/MFLPlayer', addressMap);
    await testsUtils.deployContract('MFLPack', to, 'packs/MFLPack', addressMap);
    await testsUtils.deployContract('MFLClub', to, 'clubs/MFLClub', addressMap);
    return addressMap;
  },

};
