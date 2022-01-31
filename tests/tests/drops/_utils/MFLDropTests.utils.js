import {getAccountAddress, getServiceAddress} from 'flow-js-testing';
import {testsUtils} from '../../_utils/tests.utils';

export const MFLDropTestsUtils = {

  async deployMFLDropContract(toAccountName) {
    const serviceAddress = await getServiceAddress();
    const to = await getAccountAddress(toAccountName);

    const addressMap = {};
    await testsUtils.deployContract('NonFungibleToken', serviceAddress, '_libs/NonFungibleToken', addressMap);
    await testsUtils.deployContract('MetadataViews', serviceAddress, '_libs/MetadataViews', addressMap);
    await testsUtils.deployContract('FUSD', to, '_libs/FUSD', addressMap);
    await testsUtils.deployContract('MFLAdmin', to, 'core/MFLAdmin', addressMap);
    await testsUtils.deployContract('MFLPackTemplate', to, 'packs/MFLPackTemplate', addressMap);
    await testsUtils.deployContract('MFLViews', to, 'views/MFLViews', addressMap);
    await testsUtils.deployContract('MFLPack', to, 'packs/MFLPack', addressMap);
    await testsUtils.deployContract('MFLDrop', to, 'drops/MFLDrop', addressMap);
    return addressMap;
  },

  async createDropAdmin(rootAdminAccountName, receiverAccountName) {
    const rootAdminAcctAddress = await getAccountAddress(rootAdminAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName);

    await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [receiverAcctAddress]});
    const args = [receiverAcctAddress, `/private/${receiverAccountName}-dropAdminClaim`];
    await testsUtils.shallPass({
      name: 'mfl/drops/give_drop_admin_claim.tx',
      args,
      signers: [rootAdminAcctAddress],
    });
  },
};
